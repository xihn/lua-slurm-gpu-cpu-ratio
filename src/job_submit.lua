-- GLOBAL VARIABLES --
myname = "job_submit_require_cpu_gpu_ratio"
enabled = true
partition = "es1"
default_ratio = 2.0
epsilon = 1e-9

local card_ratios = {
    gtrx2080ti = 2.0,  -- 4 x GRTX2080TI, 8 CPU Cores, 2.0 Cores per GPU (n0024-42.es1)
    a40        = 16.0, -- 4 x A40, 64 CPU Cores, 16.0 Cores per GPU 
    v100       = 4.0,  -- 2 x V100, 8 CPU Cores, 4.0 Cores per GPU 
    a100       = 16.0, -- 4 x A100, 64 CPU Cores, 16.0 Cores per GPU (n0062.es1)
    h100       = 6.0,  -- 8 x H100, 112 CPU Cores, 14.0 Cores per GPU 
    grtx8000   = 16.0  -- 4 x GRTX8000, 64 CPU Cores, 16.0 Cores per GPU (n0060.es1)
}

-- LOCAL FUNCTIONS --

local function are_equal(a, b)
    return math.abs(a - b) < epsilon
end

local function check_single_gpu_request(ncpu, gpu_name, gpu_count)
    local required_ratio = default_ratio
    if gpu_name and card_ratios[gpu_name] then
        required_ratio = card_ratios[gpu_name]
    elseif gpu_name then
        slurm.log_info(myname .. ": Missing ratio info for GPU '" .. gpu_name ..
                       "', using default ratio " .. default_ratio)
    else
        slurm.log_info(myname .. ": No GPU name specified, using default ratio " .. default_ratio)
    end

    local ratio = ncpu / gpu_count
    if not are_equal(ratio, required_ratio) then
        slurm.log_user("Error: Requested CPU/GPU ratio " .. ratio ..
                       " does not match required ratio " .. required_ratio)
        return slurm.ESLURM_INVALID_GRES
    end

    return slurm.SUCCESS
end

local function parse_and_check_gpu_requests(part, tres, ncpu)
    if part ~= partition then
        return slurm.SUCCESS
    end

    if not tres or tres == "" or tres == slurm.NO_VAL then
        slurm.log_info(myname .. ": No GRES specified on partition " .. part .. ", skipping ratio checks.")
        return slurm.SUCCESS
    end

    for entry in string.gmatch(tres, "([^+]+)") do
        local lower_entry = string.lower(entry)
        local gpu_name, gpu_count_str = string.match(lower_entry, "^gpu:([a-z0-9]+):(%d+)$")
        local gpu_count

        if gpu_name and gpu_count_str then
            gpu_count = tonumber(gpu_count_str)
            if not gpu_count or gpu_count <= 0 then
                slurm.log_user(myname .. ": Invalid GPU count '" .. tostring(gpu_count_str) ..
                               "' in request '" .. entry .. "'")
                return slurm.ESLURM_INVALID_GRES
            end
        else
            local gpu_count_str_only = string.match(lower_entry, "^gpu:(%d+)$")
            if gpu_count_str_only then
                gpu_count = tonumber(gpu_count_str_only)
                gpu_name = nil
                if not gpu_count or gpu_count <= 0 then
                    slurm.log_user(myname .. ": Invalid GPU count '" .. tostring(gpu_count_str_only) ..
                                   "' in request '" .. entry .. "'")
                    return slurm.ESLURM_INVALID_GRES
                end
            else
                slurm.log_user(myname .. ": Invalid GPU format in TRES '" .. entry .. "'")
                return slurm.ESLURM_INVALID_GRES
            end
        end

        local rc = check_single_gpu_request(ncpu, gpu_name, gpu_count)
        if rc ~= slurm.SUCCESS then
            return rc
        end
    end

    return slurm.SUCCESS
end

-- SLURM FUNCTIONS --

function slurm_job_submit(job_desc, part_list, submit_uid)
    if not enabled then
        return slurm.SUCCESS
    end

    local part = job_desc.partition or ""
    local tres = job_desc.tres_per_node
    local ncpu = job_desc.min_cpu or 1

    -- Think of this like python try sort of ?
    local status, result = pcall(parse_and_check_gpu_requests, part, tres, ncpu)
    if not status then
        -- Handle the error (result contains the error message)
        slurm.log_error("Error in parse_and_check_gpu_requests: " .. result)
        return slurm.ERROR
    end

    return result
end

function slurm_job_modify(job_desc, job_rec, part_list, modify_uid)
	if not enabled then
        return slurm.SUCCESS
    end

    local part = job_desc.partition or ""
    local tres = job_desc.tres_per_node
    local ncpu = job_desc.min_cpu or 1

    return parse_and_check_gpu_requests(part, tres, ncpu)
end
