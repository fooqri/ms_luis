defmodule MsLuis do

  @moduledoc """
  The `MsLuis` module is used to send requests to the LUIS service.
  """

  @doc """
  Sends a request to the LUIS service for the given `query`
  
  Args
  
  * `query` - a binary that is to be sent to the LUIS service

  Usage

  MsLuis.get_intent("turn off the lights")
  # {:ok, %{"topScoringIntent" => "lights_off", ...}}
  """
  @spec get_intent(binary) :: {atom, map} | {:error, binary | atom}
  def get_intent(query) do
    query = URI.encode(query)
    opts = []
    
    with config             <- Application.get_env(:ms_luis, :config),
	 {:ok, url}         <- build_url(config, query),
         {:ok, merged_opts} <- build_opts(config, opts)
      do
      Ivar.new(:get, url, merged_opts)
      |> Ivar.send
      |> Ivar.unpack
      |> respond
      else
	err -> err
    end
  end


  defp build_ssl_protocol_string(version) do
    default_protocol = :"tlsv1.2"
    [ssl: [{:versions, [version || default_protocol]}]]
  end

  defp build_opts(nil, _), do: {:error, "No config found for :ms_luis"}
  defp build_opts(config, opts) do
    merged_opts = config[:ssl_protocol]
    |> build_ssl_protocol_string()
    |> Keyword.merge(opts)

    {:ok, merged_opts}
  end
  
  defp build_url(nil, _), do: {:error, "No config found for :ms_luis"}
  defp build_url(config, query) do
    with {:ok, url}     <- Keyword.fetch(config, :url),
         {:ok, app_key} <- Keyword.fetch(config, :app_key),
         {:ok, sub_key} <- Keyword.fetch(config, :sub_key)
      do
      {:ok, "#{url}/luis/v2.0/apps/#{app_key}?subscription-key=#{sub_key}&verbose=true&q=#{query}"}
      else
	_ -> {:error, "There is a missing value in the config for :ms_luis"}
    end
  end

  defp respond({_, %HTTPoison.Error{reason: reason}}), do: {:error, reason}
  defp respond({content, _}), do: {:ok, content}
  defp respond(resp), do: resp
end
