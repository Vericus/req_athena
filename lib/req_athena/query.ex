defmodule ReqAthena.Query do
  @moduledoc false
  # This module represents a query and its attributes.

  defstruct query: nil, params: nil, statement_name: nil, prepared: false, unload: nil

  @doc """
  Returns if this query is using params or not.
  """
  def parameterized?(%__MODULE__{} = query), do: List.wrap(query.params) != []

  @doc """
  Builds the final query to send to the Athena service.
  """
  def to_query_string(%__MODULE__{query: query_string, unload: [_ | _] = opts} = query)
      when is_binary(query_string) do
    # UNLOAD works only with SELECT
    if is_select(query) do
      {to, props} = Keyword.pop!(opts, :to)

      props =
        Enum.intersperse(
          for(
            {key, value} <- props,
            not is_nil(value),
            do: [Atom.to_string(key), " = ", encode_value(value)]
          ),
          ", "
        )

      IO.iodata_to_binary([
        "UNLOAD (",
        query_string,
        ")",
        "\n",
        "TO ",
        encode_value(to),
        "\n",
        "WITH (",
        props,
        ")"
      ])
    else
      query_string
    end
  end

  def to_query_string(%__MODULE__{query: query_string}), do: query_string

  defp encode_value(value) when is_binary(value), do: "'#{value}'"
  defp encode_value(%Date{} = value), do: to_string(value) |> encode_value()

  defp encode_value(%DateTime{} = value) do
    value
    |> DateTime.to_naive()
    |> encode_value()
  end

  defp encode_value(%NaiveDateTime{} = value) do
    value
    |> NaiveDateTime.truncate(:millisecond)
    |> to_string()
    |> encode_value()
  end

  defp encode_value(value), do: value

  def execution_params(%__MODULE__{params: params} = query) do
    if parameterized?(query) do
      Enum.map(params, &encode_value/1)
    else
      nil
    end
  end

  def is_select(%{query: query_string})
      when is_binary(query_string) do
    query_string =~ ~r/^[\s]*select/i
  end

  def can_use_unload?(_), do: false

  @doc """
  Add attributes required by the "UNLOAD" command.

  See: https://docs.aws.amazon.com/athena/latest/ug/unload.html
  """
  def with_unload(%__MODULE__{} = query, opts) do
    opts =
      Keyword.validate!(opts,
        to: nil,
        format: "PARQUET",
        compression: nil,
        compression_level: nil,
        field_delimiter: nil,
        partitioned_by: nil
      )

    if opts[:to] in ["", nil] do
      raise "`:to` is required by UNLOAD"
    end

    %{query | unload: opts}
  end
end
