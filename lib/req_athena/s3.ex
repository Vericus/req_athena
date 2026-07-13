defmodule ReqAthena.S3 do
  @moduledoc false
  def new(aws_credentials, options \\ []) do
    Req.new()
    |> Req.Request.register_options([:s3_extra_step, :service])
    |> Req.Request.merge_options(options)
    |> ReqS3.attach(aws_sigv4: aws_credentials)
    |> maybe_add_s3_extra_step(options)
  end

  defp maybe_add_s3_extra_step(request, options) do
    case options[:s3_extra_step] do
      nil ->
        request

      {mod, fun} when is_atom(mod) and is_atom(fun) ->
        apply(mod, fun, [request])
    end
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
