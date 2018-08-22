defmodule SnitchApi.Payment.HostedPayment do
  @moduledoc """
  Utilites for hosted payments.
  """

  alias Snitch.Data.Model.HostedPayment
  alias Snitch.Data.Model.Order
  alias Snitch.Data.Model.Payment
  alias Snitch.Data.Model.PaymentMethod

  def payment_order_context(%{status: "success"} = params) do
    payment_params = %{status: "paid"}
    update_hosted_payment(params, payment_params)
  end

  def payment_order_context(%{status: "failure"} = params) do
    payment_params = %{status: "failed"}
    update_hosted_payment(params, payment_params)
  end

  def get_payment_preferences(payment_method_id) do
    payment_method = PaymentMethod.get(payment_method_id)
    credentials = payment_method.preferences()
    live_mode = payment_method.live_mode?
    %{credentials: credentials, live_mode: live_mode}
  end

  defp update_hosted_payment(params, payment_params) do
    order_id = params.order_id
    payment_id = params.payment_id
    transaction_id = params.transaction_id
    payment_source = params.payment_source
    raw_response = params.raw_response
    hosted_payment = HostedPayment.from_payment(payment_id)

    hosted_params = %{
      transaction_id: transaction_id,
      payment_source: payment_source,
      raw_response: raw_response
    }

    with {:ok, hosted_payment} <-
           HostedPayment.update(hosted_payment, hosted_params, payment_params),
         {:ok, order} <- Order.get(order_id) do
      payment = Payment.get(hosted_payment.payment_id)
      {:ok, order, payment}
    else
      {:error, _} -> {:error, "some error occured"}
    end
  end
end