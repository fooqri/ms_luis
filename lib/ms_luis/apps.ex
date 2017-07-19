defmodule MsLuis.Apps do
  @moduledoc """
    The `MsLuis.Apps` module is used to manage the `apps` resource on the Microsoft LUIS API.
  """

  alias Ivar.Headers

  @base_url "https://westus.api.cognitive.microsoft.com"

  @doc """
  Sends a request to create an new application and returns the ID for the newly created application

  Args

    * `params` - a map that represents the data required for the add application endpoint

  Usage

      MsLuis.Apps.add(%{name: "My App", culture: "en-us"})
      # {:ok, "<GUID>"}
  """
  @spec add(map) :: {:ok, binary} | {:error, binary | atom}
  def add(params), do: send_request(params, :post)

  @doc """
  Sends a request to create an new prebuilt application and returns the ID for the newly created application

  Args

    * `params` - a map that represents the data required for the add prebuilt application endpoint

  Usage

      MsLuis.Apps.add_prebuilt(%{domain_name: "Web", culture: "en-us"})
      # {:ok, "4754ab84-7590-4bbe-a723-38151a7fee09"}
  """
  @spec add_prebuilt(map) :: {:ok, binary} | {:error, binary | atom}
  def add_prebuilt(params) do
    params
    |> replace_key(:domain_name, :domainName)
    |> send_request(:post, "customprebuiltdomains")
  end

  @doc """
  Sends a request to delete an existing application

  Args

    * `app_id` - a binary containing the id for the application to be deleted

  Usage

      MsLuis.Apps.delete("4754ab84-7590-4bbe-a723-38151a7fee09")
      # :ok
  """
  @spec delete(binary) :: :ok | {:error, binary | atom}
  def delete(app_id), do: send_request(app_id, :delete)

  def get_query_logs(app_id, opts \\ []) do
    send_request(app_id, :get, "queryLogs")
  end

  defp replace_key(map, from, to) do
    value = Map.get(map, from)

    map
    |> Map.put(to, value)
    |> Map.drop([from])
  end

  #defp send_request(params), do: send_request(params, :get, "")
  defp send_request(params, method), do: send_request(params, method, "")
  defp send_request(params, method, endpoint) do
    with config         <- Application.get_env(:ms_luis, :config),
         {:ok, url}     <- build_url(params, endpoint, config),
         {:ok, sub_key} <- Keyword.fetch(config, :sub_key)
    do
      Ivar.new(method, url)
      |> put_req_body(method, params)
      |> Headers.put("ocp-apim-subscription-key", sub_key)
      |> Ivar.send
      |> Ivar.unpack
      |> respond
    else
      err -> err
    end
  end

  defp respond({_, %HTTPoison.Error{reason: reason}}), do: {:error, reason}
  defp respond({"", _}), do: :ok
  defp respond({content, _}), do: {:ok, content}
  defp respond(resp), do: resp

  defp put_req_body(req, method, _) when method in [:get, :delete],
    do: req
  defp put_req_body(req, _, params),
    do: Ivar.put_body(req, params, :json)

  defp build_url_query(url, params) when is_binary(params), do: "#{url}/#{params}"
  defp build_url_query(url, _), do: url

  defp build_url(_, _, nil), do: {:error, "No config found for :ms_luis"}
  defp build_url(params, endpoint, config) do
    url = case Keyword.fetch(config, :url) do
      {:ok, cfg_url} -> cfg_url
      _ -> @base_url
    end
    |> Kernel.<>("/luis/api/v2.0/apps")
    |> build_url_query(params)
    |> append_endpoint(endpoint)

    {:ok, url}
  end

  defp append_endpoint(url, ""), do: url
  defp append_endpoint(url, endpoint), do: "#{url}/#{endpoint}"
end
