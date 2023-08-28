{
	"subject": {
        "country": {{ toJson .Insecure.User.country }},
        "organization": {{ toJson .Insecure.User.organization }},
        "commonName": {{ toJson .Subject.CommonName }}
        },
	"issuer": {
        "country": {{ toJson .Insecure.User.country }},
        "organization": {{ toJson .Insecure.User.organization }},
        "commonName": {{ toJson .Subject.CommonName }}
        },
	"basicConstraints": {
		"isCA": true,
		"maxPathLen": 1
	},
	"keyUsage": ["certSign", "crlSign"]
	{{- if typeIs "*rsa.PublicKey" .Insecure.CR.PublicKey }}
  	, "signatureAlgorithm": "SHA256-RSAPSS"
	{{- end }}
}