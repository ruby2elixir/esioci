defmodule Esioci.Db.Test do
  import Logger
  use ExUnit.Case, async: true

  test "return last build status" do
    build = %EsioCi.Build{state: "CREATED-esio-last-build-status", project_id: 1}
    created_build = EsioCi.Repo.insert!(build)
    {_, inserted_at} = Ecto.DateTime.dump(created_build.inserted_at)
    {_, updated_at} = Ecto.DateTime.dump(created_build.updated_at)
    assert inspect EsioCi.Db.get_build_with_id(1, "last") == [[created_build.id,
            "CREATED-esio-last-build-status", "",
            inserted_at,
            updated_at]]
  end

  test "return build with id" do
    build = %EsioCi.Build{state: "esioci_return_build_with_id", project_id: 1}
    created_build = EsioCi.Repo.insert!(build)
    {_, inserted_at} = Ecto.DateTime.dump(created_build.inserted_at)
    {_, updated_at} = Ecto.DateTime.dump(created_build.updated_at)
    Logger.error created_build.id
    assert inspect EsioCi.Db.get_build_with_id(1, "#{created_build.id}") == [[created_build.id,
            "esioci_return_build_with_id", "",
            inserted_at,
            updated_at
          ]]
  end

  test "return last build status with id" do
    assert EsioCi.Db.get_build_with_id(1, "esio") == :error
  end

end
