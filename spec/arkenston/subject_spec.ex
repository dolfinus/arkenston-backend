defmodule Arkenston.SubjectSpec do
  alias Arkenston.Subject.UserSpec
  alias Arkenston.Subject
  use ESpec

  context "subject", module: :repo, subject: true do
    use UserSpec
  end
end
