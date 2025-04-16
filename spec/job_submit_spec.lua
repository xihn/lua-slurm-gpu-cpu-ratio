-- Stub out the slurm table and its constants
_G.slurm = {
  SUCCESS = 0,
  ESLURM_INVALID_GRES = 1,
  ERROR = 2,
  NO_VAL = "NO_VAL",
  log_info = function(msg) end,
  log_user = function(msg) end,
  log_error = function(msg) end
}

-- Load the job submit script. Adjust the relative path if needed.
dofile("src/job_submit.lua")

describe("Job Submission", function()

  describe("slurm_job_submit", function()

    it("returns SUCCESS when partition does not match", function()
      local job_desc = {
        partition = "other",
        tres_per_node = "gpu:a40:1", -- even if tres is provided, partition doesn't match
        min_cpu = 16
      }
      local rc = slurm_job_submit(job_desc, nil, 1001)
      assert.are.equal(slurm.SUCCESS, rc)
    end)

    it("returns SUCCESS if no tres provided", function()
      local job_desc = {
        partition = "es1",
        tres_per_node = "",
        min_cpu = 4
      }
      local rc = slurm_job_submit(job_desc, nil, 1001)
      assert.are.equal(slurm.SUCCESS, rc)
    end)

    it("returns SUCCESS with valid named GPU request", function()
      -- for gpu:a40:1, required ratio is 16.0; min_cpu must be 16
      local job_desc = {
        partition = "es1",
        tres_per_node = "gpu:a40:1",
        min_cpu = 16
      }
      local rc = slurm_job_submit(job_desc, nil, 1001)
      assert.are.equal(slurm.SUCCESS, rc)
    end)

    it("returns SUCCESS with valid unnamed GPU request", function()
      -- when no GPU name is provided, default_ratio=2.0 must match
      local job_desc = {
        partition = "es1",
        tres_per_node = "gpu:1",
        min_cpu = 2
      }
      local rc = slurm_job_submit(job_desc, nil, 1001)
      assert.are.equal(slurm.SUCCESS, rc)
    end)

    it("returns ESLURM_INVALID_GRES for mismatched ratio", function()
      -- for gpu:v100:1, required ratio is 4.0. Using 8 CPU cores
      local job_desc = {
        partition = "es1",
        tres_per_node = "gpu:v100:1",
        min_cpu = 8
      }
      local rc = slurm_job_submit(job_desc, nil, 1001)
      assert.are.equal(slurm.ESLURM_INVALID_GRES, rc)
    end)

    it("returns ESLURM_INVALID_GRES when gpu count is invalid (zero)", function()
      local job_desc = {
        partition = "es1",
        tres_per_node = "gpu:a40:0",
        min_cpu = 16
      }
      local rc = slurm_job_submit(job_desc, nil, 1001)
      assert.are.equal(slurm.ESLURM_INVALID_GRES, rc)
    end)

    it("returns ESLURM_INVALID_GRES for invalid GPU format", function()
      local job_desc = {
        partition = "es1",
        tres_per_node = "invalid_format",
        min_cpu = 4
      }
      local rc = slurm_job_submit(job_desc, nil, 1001)
      assert.are.equal(slurm.ESLURM_INVALID_GRES, rc)
    end)

    it("handles multiple GPU entries and fails if any entry is invalid", function()
      -- First entry is valid; second entry is invalid (mismatched ratio)
      -- for gpu:a40:1, 16 cpu cores works but for gpu:v100:1, 16 cpu cores is wrong.
      local job_desc = {
        partition = "es1",
        tres_per_node = "gpu:a40:1+gpu:v100:1",
        min_cpu = 16
      }
      local rc = slurm_job_submit(job_desc, nil, 1001)
      assert.are.equal(slurm.ESLURM_INVALID_GRES, rc)
    end)
  end)

  describe("slurm_job_modify", function()

    it("returns SUCCESS for valid modify requests", function()
      local job_desc = {
        partition = "es1",
        tres_per_node = "gpu:a40:1",
        min_cpu = 16
      }
      local dummy_job_rec = {}
      local rc = slurm_job_modify(job_desc, dummy_job_rec, nil, 1002)
      assert.are.equal(slurm.SUCCESS, rc)
    end)

    it("returns ESLURM_INVALID_GRES for modify requests with invalid tres", function()
      local job_desc = {
        partition = "es1",
        tres_per_node = "gpu:v100:1", -- 8 cpu cores required for valid ratio would be 4, here we try 8
        min_cpu = 8
      }
      local dummy_job_rec = {}
      local rc = slurm_job_modify(job_desc, dummy_job_rec, nil, 1002)
      assert.are.equal(slurm.ESLURM_INVALID_GRES, rc)
    end)

  end)

end)
