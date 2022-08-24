#!/usr/bin/env elixir

defmodule Hush.Release do
  def run([version]) do
    # ensure version is valid
    Version.parse!(version)

    ensure_git_clean()

    replace_infile("CHANGELOG.md", ~r/## Next/, "## v#{version}")
    replace_infile("mix.exs", ~r/@version \".*\"/, "@version \"#{version}\"")

    replace_infile(
      "README.md",
      ~r/{:hush, \"~> .*\"}/,
      "{:hush, \"~> #{version}\"}"
    )

    show_git_diff()
    ensure_user_wants_release()

    git(["add", "CHANGELOG.md", "README.md", "mix.exs"])
    git(["commit", "-m", "v#{version}"])
    git(["tag", "v#{version}", "-m", "v#{version}"])
    git(["push"])
    git(["push", "--tags"])
  end

  def run([]) do
    tags =
      git(["tag", "--list", "--sort=-v:refname"])
      |> then(fn {contents, 0} -> contents end)
      |> String.trim()
      |> String.split("\n")
      |> Enum.slice(0..5)

    """
    Error: Missing version
    Usage: bin/release.exs 0.0.0

    Last 5 tags:
    - #{tags |> Enum.join("\n- ")}
    """
    |> IO.write()
  end

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
      git(["checkout", "HEAD", "CHANGELOG.md", "README.md", "mix.exs"])
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
