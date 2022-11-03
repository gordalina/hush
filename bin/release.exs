#!/usr/bin/env elixir

defmodule Hush.Release do
  def run([version]) do
    parsed = Version.parse!(version)
    is_release? = Version.match?(parsed, ">= 0.0.0", allow_pre: false)

    ensure_git_clean()

    if is_release? do
      replace_infile("CHANGELOG.md", ~r/## Next/, "## v#{version}")
      replace_infile("mix.exs", ~r/@version \".*\"/, "@version \"#{version}\"")

      replace_infile(
        "README.md",
        ~r/{:hush, \"~> .*\"}/,
        "{:hush, \"~> #{parsed.major}.#{parsed.minor}\"}"
      )

      show_git_diff()
    end

    ensure_user_wants_release()

    if is_release? do
      git(["add", "CHANGELOG.md", "README.md", "mix.exs"])
      git(["commit", "-m", "v#{version}"])
    end

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
