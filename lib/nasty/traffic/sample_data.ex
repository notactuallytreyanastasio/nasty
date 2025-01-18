defmodule Nasty.Traffic.SampleData do
  @moduledoc """
  Contains sample data for traffic simulation
  """

  # List of common tech topics to combine into titles
  @topics [
    "Machine Learning",
    "Neural Networks",
    "Data Science",
    "Cloud Computing",
    "DevOps",
    "Microservices",
    "Blockchain",
    "Cybersecurity",
    "IoT",
    "Edge Computing",
    "Quantum Computing",
    "Artificial Intelligence",
    "Big Data",
    "Web Development",
    "Mobile Development",
    "Game Development",
    "UI/UX Design",
    "Database Systems",
    "Network Security",
    "Cloud Native",
    "Serverless",
    "Containerization"
  ]

  @actions [
    "Guide to",
    "Introduction to",
    "Deep Dive into",
    "Understanding",
    "Mastering",
    "Best Practices for",
    "Advanced",
    "Fundamentals of",
    "Essential",
    "Complete Guide to",
    "Professional",
    "Modern",
    "Practical",
    "Comprehensive",
    "Ultimate Guide to",
    "Getting Started with",
    "Learning",
    "Exploring",
    "Building with",
    "Working with"
  ]

  @platforms [
    "AWS",
    "Azure",
    "GCP",
    "Kubernetes",
    "Docker",
    "React",
    "Vue.js",
    "Angular",
    "Node.js",
    "Python",
    "Ruby",
    "Go",
    "Rust",
    "Java",
    "Kotlin",
    "Swift",
    "Flutter",
    "React Native",
    "TensorFlow",
    "PyTorch",
    "PostgreSQL",
    "MongoDB",
    "Redis",
    "Kafka",
    "RabbitMQ",
    "Elasticsearch",
    "GraphQL",
    "REST APIs"
  ]

  @contexts [
    "in Production",
    "for Beginners",
    "for Enterprise",
    "at Scale",
    "in 2024",
    "for Startups",
    "for Teams",
    "in Practice",
    "with Examples",
    "Step by Step",
    "from Scratch",
    "for Professionals",
    "Made Simple",
    "Explained",
    "in Action",
    "for Modern Apps",
    "Deep Dive",
    "Quick Start",
    "Advanced Topics",
    "Basics"
  ]

  @domains [
    "medium.com",
    "dev.to",
    "hashnode.com",
    "github.com",
    "gitlab.com",
    "stackoverflow.com",
    "youtube.com",
    "udemy.com",
    "coursera.org",
    "edx.org",
    "pluralsight.com",
    "linkedin.com",
    "microsoft.com",
    "google.com",
    "amazon.com",
    "digitalocean.com",
    "heroku.com",
    "netlify.com",
    "vercel.com",
    "cloudflare.com"
  ]

  @tags [
    "programming",
    "development",
    "software",
    "tech",
    "coding",
    "web",
    "mobile",
    "cloud",
    "devops",
    "security",
    "data",
    "ai",
    "ml",
    "database",
    "frontend",
    "backend",
    "fullstack",
    "architecture",
    "infrastructure",
    "networking",
    "automation",
    "testing",
    "deployment",
    "monitoring",
    "analytics"
  ]

  @doc """
  Generates a unique, sensical title by combining different elements
  """
  def generate_title do
    "#{Enum.random(@actions)} #{Enum.random(@topics)} #{Enum.random(@contexts)}"
  end

  @doc """
  Generates a list of 1000+ unique titles
  """
  def all_titles do
    for action <- @actions,
        topic <- @topics,
        context <- @contexts,
        into: [] do
      "#{action} #{topic} #{context}"
    end
  end

  @doc """
  Generates a random URL using the title
  """
  def generate_url(title) do
    slug =
      title
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9\s]/, "")
      |> String.replace(~r/\s+/, "-")

    domain = Enum.random(@domains)
    "https://#{domain}/#{slug}"
  end

  @doc """
  Generates a random description
  """
  def generate_description do
    words = Enum.take_random(@topics ++ @platforms ++ @contexts, 5)
    "Explore #{Enum.join(words, " ")} and more in this comprehensive guide."
  end

  @doc """
  Generates random tags
  """
  def generate_tags do
    Enum.take_random(@tags, :rand.uniform(5))
  end
end
