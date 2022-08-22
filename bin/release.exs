#!/usr/bin/env elixir

defmodule Hush.Release do
  def run([version]) do
    # ensure version is valid
    Version.parse!(version)

    ensure_git_clean()

    replace_infile("mix.exs", ~r/@version \".*\"/, "@version \"#{version}\"")
    replace_infile("README.md", ~r/{:hush, \"~> .*\"}/, "{:hush, \"~> #{version}\"}")

    show_git_diff()
    ensure_user_wants_release()

    git(["add", "README.md", "mix.exs"])
    git(["commit", "-m", "Bump version to v#{version}"])
    git(["tag", "v#{version}"])
    git(["push"])
    git(["push", "--tags"])
  end

  def run([]), do: IO.puts("Need to supply an argument with a version in the format: 0.0.0")

  defp replace_infile(file, pattern, subst) do
    file
    |> File.read!()
    |> String.replace(pattern, subst)
    |> case do
      contents -> File.write!(file, contents)
    end
  end

  defp ensure_git_clean() do
    if git(["status", "--porcelain"]) != {"", 0} do
      raise RuntimeError, message: "Git repository is not clean"
    end
  end

  defp ensure_user_wants_release() do
    if IO.gets("Do you want to release this version [y/N]? ") != "y\n" do
      git(["checkout", "HEAD", "README.md", "mix.exs"])
      raise RuntimeError, message: "Release aborted"
    end
  end

  defp show_git_diff() do
    git(["diff", "--color"])
    |> Tuple.to_list()
    |> hd()
    |> IO.puts()
  end

  defp git(args), do: System.cmd("git", args)
end

System.argv() |> Hush.Release.run()
