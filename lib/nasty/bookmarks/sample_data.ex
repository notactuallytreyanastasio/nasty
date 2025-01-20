defmodule Nasty.Bookmarks.SampleData do
  @topics [
    "DevOps", "Kubernetes", "Docker", "AWS", "Cloud Computing",
    "Microservices", "API Design", "REST APIs", "GraphQL",
    "Security", "Testing", "CI/CD", "Python", "Ruby", "Elixir",
    "JavaScript", "TypeScript", "React", "Vue.js", "Angular",
    "Node.js", "Machine Learning", "AI", "Data Science",
    "Blockchain", "IoT", "System Architecture", "Database Systems",
    "Edge Computing", "Quantum Computing", "Mobile Development",
    "Web Development", "Frontend", "Backend", "Full Stack"
  ]

  @domains [
    "dev.to", "medium.com", "github.com", "youtube.com",
    "aws.amazon.com", "microsoft.com", "google.com", "netflix.com",
    "uber.com", "airbnb.com", "spotify.com", "heroku.com",
    "digitalocean.com", "pluralsight.com", "udemy.com"
  ]

  @tag_pool [
    "development", "programming", "software", "tech", "tutorial",
    "guide", "howto", "tips", "best-practices", "architecture",
    "design", "patterns", "infrastructure", "deployment", "devops",
    "cloud", "aws", "azure", "gcp", "kubernetes", "docker",
    "containers", "microservices", "api", "rest", "graphql",
    "frontend", "backend", "fullstack", "web", "mobile", "ios",
    "android", "react", "vue", "angular", "node", "python",
    "javascript", "typescript", "java", "golang", "rust", "elixir",
    "phoenix", "rails", "django", "spring", "database", "sql",
    "nosql", "mongodb", "postgresql", "redis", "elasticsearch",
    "kafka", "rabbitmq", "security", "authentication", "testing",
    "ci-cd", "monitoring", "logging", "analytics", "ml", "ai",
    "data-science", "blockchain", "iot", "serverless"
  ]

  def generate_title do
    topic = Enum.random(@topics)
    templates = [
      "Ultimate Guide to #{topic}",
      "#{topic} Deep Dive",
      "Getting Started with #{topic}",
      "Advanced #{topic} Explained",
      "Practical #{topic} in Action",
      "#{topic} Best Practices",
      "#{topic} for Beginners",
      "Mastering #{topic}",
      "#{topic} Quick Start",
      "Working with #{topic}"
    ]
    Enum.random(templates)
  end

  def generate_url(title) do
    domain = Enum.random(@domains)
    slug = title
           |> String.downcase()
           |> String.replace(~r/[^a-z0-9]+/, "-")
           |> String.trim("-")
    "https://#{domain}/#{slug}"
  end

  def generate_description do
    topics = Enum.take_random(@topics, :rand.uniform(5) + 2)
    "Explore #{Enum.join(topics, " ")} and more in this comprehensive guide."
  end

  def generate_tags do
    Enum.take_random(@tag_pool, :rand.uniform(4) + 1)
  end
end
