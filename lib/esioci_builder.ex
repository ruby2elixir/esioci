defmodule EsioCi.Builder do
  require Logger
  require Poison

  def build do
    receive do
      {sender, msg, build_id, type} ->
        try do
          case type do
            "gh" -> Logger.debug "Run build from github"
                    EsioCi.Common.change_bld_status(build_id, "RUNNING")
                    status = msg
                              |> parse_github
                              |> clone
                              |> parse_yaml
                    Logger.debug status
                    EsioCi.Common.change_bld_status(build_id, "COMPLETED")
                    Logger.info "Build completed"
            _ ->
              Logger.error "Only github is supported"
              Logger.error "Build failed"
              EsioCi.Common.change_bld_status(build_id, "FAILED")
          end
        rescue
          e -> EsioCi.Common.change_bld_status(build_id, "FAILED")
        end

    end
  end

  def parse_github(req_json) do
    git_url     = req_json.params["repository"]["git_url"]
    commit_sha  = req_json.params["head_commit"]["id"]
    repo_name   = req_json.params["repository"]["full_name"]
    Logger.debug "Repository url: #{git_url}"
    Logger.debug "Repository name: #{repo_name}"
    Logger.debug "Commit sha: #{commit_sha}"

    {:ok, git_url, repo_name, commit_sha}
  end

  def clone({ok, git_url, repo_name, commit_sha}) do
    dst = "/tmp/build"
    cmd = "git clone #{git_url} #{dst}"
    EsioCi.Common.run("rm -rf #{dst}")
    EsioCi.Common.run(cmd)
    {:ok, dst}
  end

  def parse_yaml({ok, dst}) do
    Logger.debug "Parse yaml file"
    yaml_file = "#{dst}/esioci.yaml"
    Logger.debug yaml_file
    if File.exists?(yaml_file) do
      try do
        [yaml | _] = :yamerl_constr.file(yaml_file)
        Logger.debug "YAML from file: #{inspect yaml}"
        build_cmd = get_bld_cmd_from_yaml(yaml)
        Logger.debug "Build cmd: #{build_cmd}"
        if build_cmd != :error and is_list(build_cmd) do
          # check if build_cmd is a string
          if is_integer(List.first(build_cmd)) do
            cmd = build_cmd |> to_string
            EsioCi.Common.run(cmd, dst)
          else
            for one_cmd <- build_cmd do
              cmd = one_cmd |> to_string
              EsioCi.Common.run(cmd, dst)
            end
          end
        else
          Logger.error "Error get build_cmd from yaml"
          raise MatchError
          :error
        end
      rescue
        e -> Logger.error "Error parsing yaml"
                           raise MatchError
        #e in Protocol.UndefinedError -> Logger.error "Error parsing yaml"
                            #:error
      end
    else
      Logger.error "yaml file: #{yaml_file} doesn't exist"
      :error
    end
  end

  def get_bld_cmd_from_yaml(yaml) do
    build_cmds = :proplists.get_value('build', yaml)
    extract_cmd(build_cmds)
  end

  defp extract_cmd([]) do
    []
  end

  defp extract_cmd([head|tail]) do
    [{'exec', cmd }] = head
    cmd_str = cmd |> List.to_string
    [cmd] ++ extract_cmd(tail)
  end

end
