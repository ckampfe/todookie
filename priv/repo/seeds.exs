# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Todookie.Repo.insert!(%Todookie.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Todookie.Accounts.Scope
alias Todookie.Todos
alias Todookie.Accounts

{:ok, user} =
  Accounts.register_user(%{
    email: "me@me.com",
    password: "me"
  })

Accounts.confirm_user!(user)

board = Todos.create_board!(%{"name" => "great board"}, Scope.for_user(user))

todo_column =
  Todos.create_column!(%{"name" => "todo", "board_id" => board.id}, Scope.for_user(user))

doing_column =
  Todos.create_column!(%{"name" => "doing", "board_id" => board.id}, Scope.for_user(user))

done_column =
  Todos.create_column!(%{"name" => "done", "board_id" => board.id}, Scope.for_user(user))

Todos.create_card!(
  %{"title" => "seed the grass", "column_id" => todo_column.id},
  Scope.for_user(user)
)

Todos.create_card!(
  %{"title" => "figure out new job travel", "column_id" => doing_column.id},
  Scope.for_user(user)
)

Todos.create_card!(
  %{"title" => "something else", "column_id" => doing_column.id},
  Scope.for_user(user)
)

Todos.create_card!(
  %{"title" => "put truck title in safe deposit box", "column_id" => done_column.id},
  Scope.for_user(user)
)
