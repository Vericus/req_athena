defmodule ReqAthena.S3 do
  @moduledoc false
  def new(aws_credentials, options \\ []) do
    options |> Req.new() |> ReqS3.attach(aws_sigv4: aws_credentials)
  end

  def get_locations(req_s3, manifest_location) do
    req_s3
    |> Req.merge(decode_body: false)
    |> get_body(manifest_location)
    |> String.trim()
    |> String.split("\n")
  end

  def get_body(req_s3, location) do
    %{status: 200} = response = Req.get!(req_s3, url: location)

    response.body
  end
end
