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
# Get the bob@tom.com user
user = Repo.get_by!(Accounts.User, email: "bob@tom.com")

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

# Clear existing bookmarks for this user
Repo.delete_all(from b in Nasty.Bookmarks.Bookmark, where: b.user_id == ^user.id)

# Create bookmarks
for {title, description, url, tags, public} <- bookmarks do
  Bookmarks.create_bookmark(
    %{
      "title" => title,
      "description" => description,
      "url" => url,
      "public" => public,
      "user_id" => user.id
    },
    Enum.join(tags, ", ")
  )
end

IO.puts("Seed data created successfully!")
