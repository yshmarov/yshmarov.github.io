---
layout: post
title: "FR-DE EU Electronic eInvoicing standard (FacturX, ZUGFeRD)"
author: Yaroslav Shmarov
tags: invoice regulation eu facturx zugferd
thumbnail: /assets/thumbnails/factur-x-extended.png
---

I build a tool to convert Invoices to JSON data! Here's how you can do it.

![facturx upload demo](/assets/images/facturx-upload-demo.gif)

Extracting data from PDF invoices is a **billion** dollar problem.

The most common solutions:
- Paid softwarre like [Mindee](https://www.mindee.com), where you upload the PDF and they return a JSON with data. (I do not recommend Mindee)
- OpenAI or similar tools that have OCR (optical character recognition) (Good solution)
- You can use Ruby gem like [pdf-reader](https://github.com/yob/pdf-reader) to extract text from the PDF, but you still need to turn it into an object with key-value pairs.

But if the PDF document is FacturX-compliant, there's no problem at all!

*Factur-X is a Franco-German standard for hybrid e-invoice (PDF for users and XML data for process automation), the first implementation of the European Semantic Standard EN 16931 published by the European Commission on October 16th 2017.*

A factur-x-compliant PDF will have an XML file named `factur-x.xml` or `xrechnung.xml` attached in it's metadata.

This XML file will contain **ALL** the important data that is visible in the PDF structured as an object in XML format.

In the near future having an attached XML document will be mandatory when sending invoices to government agencies in France & Germany.

I hope **other countries** will catch up soon. 

I hope **invoicing software** will catch up soon, to stay competitive.

Useful links:

➡️ Read about [🇪🇺 EU eInvoicing](https://ec.europa.eu/digital-building-blocks/sites/display/DIGITAL/eInvoicing) 
➡️ [🇫🇷 La facturation électronique entre entreprises](https://www.economie.gouv.fr/cedef/facturation-electronique-entreprises)
➡️ Download [technical documentation](http://fnfe-mpe.org/factur-x/)

![facturx-download-docs](/assets/images/facturx-download.png)

### Extract XML from PDF with Ruby

Install [gem hexapdf](https://github.com/gettalong/hexapdf) to parse PDF metadata.

```shell
bundle add hexapdf
```

Create a job (in a Rails app), or a PORO.

```shell
rails g job PdfToXmlJob
```

Here's a job that extracts embedded files from a PDF document.

Only files that are named `factur-x.xml` or `xrechnung.xml` are  extracted.

```ruby
# app/jobs/pdf_to_xml_job.rb

# file_path = 'db/fixtures/factur-x/BASIC/BASIC_Einfach.pdf'
# file_path = 'db/fixtures/factur-x/EXTENDED/EXTENDED_Fremdwaehrung.pdf'
# PdfToXmlJob.perform_now(file_path)
class PdfToXmlJob < ApplicationJob
  queue_as :default

  VALID_FILENAME = %w[factur-x.xml xrechnung.xml].freeze

  def perform(file_path)
    pdf = HexaPDF::Document.open(file_path)
    catalog = pdf.catalog

    if catalog.key?(:Names) && catalog[:Names].key?(:EmbeddedFiles)
      embedded_files_tree = catalog[:Names][:EmbeddedFiles]
      embedded_files = embedded_files_tree.value[:Names]

      embedded_files.each_slice(2) do |name, ref|
        file_spec = pdf.object(ref)
        file_stream = file_spec[:EF][:F]
        file_name = file_spec[:UF] ? file_spec[:UF].to_s : name

        next unless VALID_FILENAME.include?(file_name)

        new_file = File.basename(file_path).gsub!('.pdf', '.xml')
        File.binwrite("db/fixtures/xml/#{new_file}", file_stream.stream)

        puts "Extracted file: #{new_file}"
      end
    else
      puts 'No embedded files found in the PDF.'
    end
  end
end
```

Write tests:

```ruby
# test/jobs/pdf_to_xml_job_test.rb
require 'test_helper'

class PdfToXmlJobTest < ActiveJob::TestCase
  # try importing all the files from subfolders within db/fixtures/factur-x
  test 'BASIC_Einfach' do
    file_path = 'db/fixtures/factur-x/BASIC/BASIC_Einfach.pdf'
    PdfToXmlJob.perform_now(file_path)

    assert File.exist?('db/fixtures/xml/BASIC_Einfach.xml')
    File.delete('db/fixtures/xml/BASIC_Einfach.xml')
  end

  test 'BASIC_Rechnungskorrektur' do
    file_path = 'db/fixtures/factur-x/BASIC/BASIC_Rechnungskorrektur.pdf'
    PdfToXmlJob.perform_now(file_path)

    assert File.exist?('db/fixtures/xml/BASIC_Rechnungskorrektur.xml')
    File.delete('db/fixtures/xml/BASIC_Rechnungskorrektur.xml')
  end
end
```

### Parse the stored XML file with Ruby

Now you can, for example, find the `IBAN` or `Account Name`:

```ruby
file_path = 'db/fixtures/xml/EXTENDED_Fremdwaehrung_invalid.xml'
raw_xml = File.read(file_path)
parsed_xml = Nokogiri::XML(raw_xml)
iban = parsed_xml.xpath('//ram:IBANID').text
account_name = parsed_xml.xpath('//ram:AccountName').text
```

**I personally prefer parsing data in JSON.**

Install [gem 'nori'](https://github.com/savonrb/nori) to convert the XML to JSON

```ruby
file_path = 'db/fixtures/xml/EXTENDED_Fremdwaehrung_invalid.xml'
raw_xml = File.read(file_path)
parser = Nori.new
hash = parser.parse(raw_xml)
parsed_hash = parser.parse(hash)
invoice_currency_code = hash.dig('rsm:CrossIndustryInvoice', 'rsm:SupplyChainTradeTransaction', 'ram:ApplicableHeaderTradeSettlement', 'ram:InvoiceCurrencyCode')
due_payable_amount = hash.dig('rsm:CrossIndustryInvoice', 'rsm:SupplyChainTradeTransaction', 'ram:ApplicableHeaderTradeSettlement', 'ram:SpecifiedTradeSettlementHeaderMonetarySummation', 'ram:DuePayableAmount')
invoice_currency_code = hash.dig('rsm:CrossIndustryInvoice', 'rsm:SupplyChainTradeTransaction', 'ram:ApplicableHeaderTradeSettlement', 'ram:InvoiceCurrencyCode')
invoice_date = DateTime.parse hash.dig('rsm:CrossIndustryInvoice', 'rsm:ExchangedDocument', 'ram:IssueDateTime', 'udt:DateTimeString')
invoice_number = hash.dig('rsm:CrossIndustryInvoice', 'rsm:ExchangedDocument', 'ram:ID')
```

### Next steps in a Rails app

- Upload & store PDFs in an `Invoice` model
- Validate whether the PDF has a valid FacturX XML attached (& store the validity boolean)
- Store the extracted XML files
