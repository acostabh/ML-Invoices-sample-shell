#!/bin/sh
echo off
token=$(jq -r ".token" token.json)
# switch a = show all invoices in descending date order, else show only pending invoices in ascending date order (created_at)
if [ $1 == "a" ]; then
  pending="false"
  order="desc"
else
  pending="true"
  order="asc"
fi

invoices=$(curl -H 'Authorization: Bearer '$token 'https://api.mavenlink.com/api/v1/invoices?order=created_at:'$order'&pending='$pending)
inv_count=$(jq -n "$invoices" | jq -r '.count')
if [ $inv_count == 0 ]; then
  echo "No invoices found!"
else
  echo ""
  echo "#################### Available Invoices ##################"
  echo ""
  echo "------------------------------------------------------------------------------------------------"
  for (( i=0; i < $inv_count; ++i ))
    do
      invoice_id=$(jq -n "$invoices" | jq -r '.results['$i'].id')
      echo "[" $((i + 1)) "]  [Title] "$(jq -n "$invoices" | jq -r '.invoices["'$invoice_id'"].title')" [ID] "$invoice_id" [Status] "$(jq -n "$invoices" | jq -r '.invoices["'$invoice_id'"].status')" [Balance] "$(jq -n "$invoices" | jq -r '.invoices["'$invoice_id'"].currency_symbol') $(jq -n "$invoices" | jq -r '.invoices["'$invoice_id'"].balance_in_cents'/100)
      echo "------------------------------------------------------------------------------------------------"

   done
   echo "Please type the invoice number you would like to see: default [1]"
   read view_invoice

   #check for entry
   if [ x$view_invoice == x ]; then
     load_invoice=0
   else
     load_invoice=$(( view_invoice - 1 ))
   fi

    # get invoice ID based on the invoice number entered above
    invoice_id=$(jq -n "$invoices" | jq -r '.results['$load_invoice'].id')
    # check if invoice number is valid
    if [ $invoice_id == null ]; then
      echo "Invoice number " $view_invoice  " not found!"
    else
      #load selected invoice based on it's ID
      invoice=$(curl -H 'Authorization: Bearer '$token 'https://api.mavenlink.com/api/v1/invoices/'$invoice_id'?include=additional_items,expenses,external_references,fixed_fee_items,recipient,time_entries,user,workspaces')

      add_item_count=$(jq -n "$invoice" | jq -r '.invoices["'$invoice_id'"].additional_item_ids' | jq length)
      time_entry_count=$(jq -n "$invoice" | jq -r '.invoices["'$invoice_id'"].time_entry_ids' | jq length)
      expense_count=$(jq -n "$invoice" | jq -r '.invoices["'$invoice_id'"].expense_ids' | jq length)
      fixed_fee_items_count=$(jq -n "$invoice" | jq -r '.invoices["'$invoice_id'"].fixed_fee_item_ids' | jq length)
      echo ""
      echo "#################### Invoice details ##################"
      echo ""
      echo " Number of Additional Items: " $add_item_count
      echo " Number of Time Entries: " $time_entry_count
      echo " Number of Expenses: " $expense_count
      echo " Number of Fixed Fee Items: " $fixed_fee_items_count
      echo ""
    fi

fi
