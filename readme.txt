this are the scripts to run the docker container like https://github.com/PyProgMo/c1_ROC714

inside the container. If u have to care for cooling, run thermal_watchdog.sh as root. 
(tweek temperature boundaries as desired. Note: for long term sustainability GPU Temp Junction should not exceed 90 °C)

Then run it, e.g. for your Qwen3-14B-Q6_K:

python3 download_model.py --repo bartowski/Qwen3-14B-GGUF --pattern "*Q6_K*"

This creates /workspace/models/Qwen3-14B-GGUF/ and drops the matching file(s) in there. A couple of things worth knowing:

--pattern uses glob matching, so it's the safer default — some repos split large quants into multiple parts (-00001-of-00002.gguf etc.), and a pattern like "*Q6_K*" grabs all of them, while --file only works for a single exact filename.
Double-check the exact repo id and quant name on the model's HF page before running — quant naming conventions vary a bit between uploaders (bartowski, unsloth, etc.), and a typo in --pattern will just silently download nothing.
If you hit a gated/private repo, pass --token or export HF_TOKEN=hf_xxx first.
