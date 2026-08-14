---
layout: post
title: Vector (semantic) search with embeddings PART 2
author: Yaroslav Shmarov
tags: rubyllm neighbour pgvector
thumbnail: /assets/static-pages/yaro-avatar.png
---

PART 2

USING OUR RAG

```ruby
class ChatController < ApplicationController
  def ask
    documents = Document.search_by_similarity(params[:query])
    context = documents.pluck(:content).join("\n---\n")

    chat = RubyLLM.chat
    chat.with_instruction("You're an assistant answering questions using company documents.")

    chat.ask("Context:\n#{context}\n\nQuestion: #{params[:query]}")
  end
end
```

REAL WORLD EXAMPLE

```ruby
class ProjectsController < ApplicationController
  def show
    chat = RubyLLM.chat
    chat.with_instruction("...")
    chat.with_instruction(
      "Here is the information of the project as json: #{@project.to_json}."
    )

    chat.ask "Summarize the data in few lines to understand the basic details of this project." do |chunk|
      Turbo::StreamsChannel.broadcast_append_to(
        @project,
        target: dom_id(@project, 'summary'),
        content: chunk.content
      )
    end
  end
end
```

```ruby
class Project < ApplicationRecord
  before_save :generate_description

  private

  def generate_description
    return if description.present?

    chat = RubyLLM.chat
    chat.with_instruction("...")
    chat.with_instruction(
      "Here is the information of the project as json: #{@project.to_json}."
    )

    response = chat.ask("Summarize the data in few lines to understand the basic details of this project")
    self.description = response.content
  end
end
```

INTRODUCING TOOLS

```ruby
class CreateProjectTool < RubyLLM::Tool
  description "Create a project"

  param :description,
        desc: "Project description",
        required: true

  def initialize(user)
    @user = user
  end

  def execute(description:)
    @user.projects.create(description: description)
  end
end
```

```ruby
class ProjectsController < ApplicationController
  def index
    chat = RubyLLM.chat

    ChatInstruction.for_projects.each do |chat_instruction|
      chat.with_instruction(chat_instruction.content)
    end

    chat.with_tool(CreateProjectTool.new(current_user))

    chat.ask params[:query]
  end
end
```

USING RUBYLLM EVERYWHERE

```ruby
class ProjectsController < ApplicationController
  def update
    if @project.update(project_params)
      EnhanceProjectJob.perform_later(@project)

      redirect_to @project
    else
      # ...
    end
  end
end
```
