---
title: dnssec_ex
date: 2023-09-01
project_lang: Elixir
summary: Elixir lib for working with DNSKEY and DS RR types
---

## About the project

Elixir lib for working with DNSKEY and DS RR types. You can read more about the motivation behind the project [here]({{< ref "blog/querying-dnssec-in-elixir-and-erlang" >}}). The source code can be found on [GitHub](https://github.com/hdahlheim/dnssec_ex).

Currently it supports the following features.

- decoding DNSKEY RR types
- decoding DS RR types
- calculating the key tag for a dnskey entry

I have some more features in mind like key validation but currently there is no timeframe for implementing them.
