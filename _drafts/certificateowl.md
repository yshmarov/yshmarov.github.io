

```ruby
namespace :api do
  namespace :vi do
    post 'certificates', to: 'certificates#create'
  end
end
```

Proof of concept app (POC)

CertificateTemplate: {
  name:
  event_modifications {
    verification[qr/link]
    send_email:boolean:false
  }
  
}

1. Select `CetificateTemplates` (2 templates with different modifications to choose from)
2. Upload recepients list CSV
3. Generate PDF & email certificates with QR

2. Within event, fill in fields that will be common for all certificates (verification:[qr/link], send_email:boolean:false)
3. Download CSV with sample data and fields
2. Upload recepients list CSV
3. Generate PDF & email certificates with QR
- Create `Event`
- Upload CSV to generate `Certificates`
- Certificate model
- send email email


roadmap?
core features
- QR codes


pricing?
types of certificates?
target audiences
- webinars
- online/offline event
- graduation
- olnine course
- test or survey
- membership
- achievenment
- conference
- program/training
- corporate training
- product certification

value proposition
- save time & automate
- professional and memorable
- boost marketing
- help employability


CertificateTemplate
name
modifications {
  recepient_name: text
  recepient_reason: text
  issued_at: datetime
  uid:
  issuer_company_name:
  issuer_logo_url:
  issuer_website_url:string
  issued_name:text
  issued_description:text
}

Event/Group/Campaign
name:string
event_url:text
expiration:
expires_at:
certificate_temaplate:references
delivery:email(default)

Certificate
event:references