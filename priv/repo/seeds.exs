# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Nasty.Repo.insert!(%Nasty.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Nasty.Repo
alias Nasty.Accounts
alias Nasty.Bookmarks
import Ecto.Query

# Get all users in the system
users = Repo.all(Accounts.User)

if Enum.empty?(users) do
  IO.puts("No users found in the system. Please create some users first.")
  System.halt(1)
end

# List of sample bookmarks
bookmarks = [
  {
    "Phoenix Framework",
    "Build rich, interactive web applications quickly with Phoenix",
    "https://phoenixframework.org",
    ["elixir", "phoenix", "web"],
    true
  },
  {
    "Elixir School",
    "Lessons about the Elixir programming language",
    "https://elixirschool.com",
    ["elixir", "learning", "programming"],
    true
  },
  {
    "Tailwind CSS",
    "A utility-first CSS framework for rapid UI development",
    "https://tailwindcss.com",
    ["css", "frontend", "design"],
    true
  },
  {
    "Hex.pm",
    "The package manager for the Erlang ecosystem",
    "https://hex.pm",
    ["elixir", "erlang", "packages"],
    true
  },
  {
    "GitHub",
    "Where the world builds software",
    "https://github.com",
    ["git", "development", "opensource"],
    true
  },
  {
    "PostgreSQL",
    "The world's most advanced open source database",
    "https://postgresql.org",
    ["database", "sql", "backend"],
    true
  },
  {
    "Docker",
    "Containerization platform for modern applications",
    "https://docker.com",
    ["devops", "containers", "deployment"],
    true
  },
  {
    "MDN Web Docs",
    "Resources for developers, by developers",
    "https://developer.mozilla.org",
    ["web", "documentation", "learning"],
    true
  },
  {
    "VS Code",
    "Code editing. Redefined.",
    "https://code.visualstudio.com",
    ["editor", "development", "tools"],
    true
  },
  {
    "Kubernetes",
    "Production-Grade Container Orchestration",
    "https://kubernetes.io",
    ["devops", "containers", "orchestration"],
    true
  },
  {
    "React",
    "A JavaScript library for building user interfaces",
    "https://reactjs.org",
    ["javascript", "frontend", "ui"],
    true
  },
  {
    "TypeScript",
    "JavaScript with syntax for types",
    "https://typescriptlang.org",
    ["javascript", "typescript", "programming"],
    true
  },
  {
    "Rust Programming Language",
    "A language empowering everyone to build reliable and efficient software",
    "https://rust-lang.org",
    ["rust", "programming", "systems"],
    true
  },
  {
    "Go Programming Language",
    "Build simple, reliable, and efficient software",
    "https://golang.org",
    ["go", "programming", "backend"],
    true
  },
  {
    "Node.js",
    "JavaScript runtime built on Chrome's V8 JavaScript engine",
    "https://nodejs.org",
    ["javascript", "backend", "runtime"],
    true
  },
  {
    "Redis",
    "Open source, in-memory data store used as a database, cache, message broker",
    "https://redis.io",
    ["database", "cache", "backend"],
    true
  },
  {
    "GraphQL",
    "A query language for your API",
    "https://graphql.org",
    ["api", "query", "backend"],
    true
  },
  {
    "AWS",
    "Amazon Web Services Cloud Platform",
    "https://aws.amazon.com",
    ["cloud", "hosting", "devops"],
    true
  },
  {
    "Nginx",
    "High performance web server",
    "https://nginx.com",
    ["webserver", "proxy", "deployment"],
    true
  },
  {
    "MongoDB",
    "The application data platform",
    "https://mongodb.com",
    ["database", "nosql", "backend"],
    true
  },
  {
    "Vue.js",
    "The Progressive JavaScript Framework",
    "https://vuejs.org",
    ["javascript", "frontend", "ui"],
    true
  },
  {
    "Jenkins",
    "Build great things at any scale",
    "https://jenkins.io",
    ["ci", "cd", "devops"],
    true
  },
  {
    "Flutter",
    "Build apps for any screen",
    "https://flutter.dev",
    ["mobile", "development", "ui"],
    true
  },
  {
    "Kotlin",
    "A modern programming language that makes developers happier",
    "https://kotlinlang.org",
    ["kotlin", "programming", "android"],
    true
  },
  {
    "Swift",
    "A powerful and intuitive programming language for iOS",
    "https://swift.org",
    ["swift", "programming", "ios"],
    true
  }
]

# For each user, clear their bookmarks and create new ones
for user <- users do
  IO.puts("Creating bookmarks for user: #{user.email}")

  # Clear existing bookmarks for this user
  {deleted, _} = Repo.delete_all(from b in Nasty.Bookmarks.Bookmark, where: b.user_id == ^user.id)
  IO.puts("Cleared #{deleted} existing bookmarks")

  # Create new bookmarks
  results = for {title, description, url, tags, public} <- bookmarks do
    case Bookmarks.create_bookmark(
      %{
        "title" => title,
        "description" => description,
        "url" => url,
        "public" => public,
        "user_id" => user.id
      },
      Enum.join(tags, ", ")
    ) do
      {:ok, _bookmark} -> :ok
      {:error, changeset} -> {:error, title, changeset}
    end
  end

  # Report results
  errors = Enum.filter(results, fn result -> match?({:error, _, _}, result) end)

  if Enum.empty?(errors) do
    IO.puts("Successfully created #{length(bookmarks)} bookmarks for #{user.email}")
  else
    IO.puts("Created bookmarks for #{user.email} with #{length(errors)} errors:")
    for {:error, title, changeset} <- errors do
      IO.puts("  Failed to create '#{title}': #{inspect(changeset.errors)}")
    end
  end
end

IO.puts("\nSeed data creation completed!")
