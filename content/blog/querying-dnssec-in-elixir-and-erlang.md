---
title: "Querying DNSSEC in Elixir/Erlang"
date: 2023-09-29
draft: false
---

At the beginning of this year I had to figure out how to work with DNS resource records types (DNS RR types) like DNSKEY and DS that are not natively supported in Elixir/Erlang.

## Background

Depending on who you ask, the need for DNSSEC might be a controversial topic, but at least in Switzerland,
there is a big push for adding DNSSEC to all .ch domains.

At work, we built an Elixir service that coordinates the provisioning of the DNSKEYs for our customers on our nameservers and then sends those keys to the .ch registry.

Because of the different ways DNSSEC can be provisioned, our service needs to check for the presence of DNSSEC keys and DS records using DNS. At first, we did the check using `dig` and `System.cmd/3` because of time constraints when we built the service.

This worked at the time, but the fact that we had to shell out for just that bit always bothered me,
so I did some digging to find out how we could do it all in Elixir.

## The inet_res Module

Thanks to Erlang and OTP querying DNS records in Elixir is very easy. The functionality to make DNS queries is provided by the `:inet_res` module and for the most part we can use an atom representation of the RR type to get the corresponding DNS results.

For example querying the A record of a domain, is as simple as `:inet_res.resolve(~c"dahlheim.ch", :in, :a)`.

```elixir
iex(1)> :inet_res.resolve(~c"dahlheim.ch", :in, :a)
{:ok,
 {:dns_rec, {:dns_header, 1, true, :query, false, false, true, true, false, 0},
  [{:dns_query, ~c"dahlheim.ch", :a, :in, false}],
  [
    {:dns_rr, ~c"dahlheim.ch", :a, :in, 0, 8216, {149, 126, 4, 11}, :undefined,
     [], false}
  ], [], []}}
```

Under the hood the `:inet_res` module maps the atom to the integer representation of the RR type. Currently `:inet_res` supports a few
[RR types](https://www.erlang.org/doc/man/inet_res.html#type-dns_rr_type) that should be enough for normal day to day DNS use.

```erlang
% Supported RR types as of erlang/otp 26.0
dns_rr_type() =
    a | aaaa | caa | cname | gid | hinfo | ns | mb | md | mg |
    mf | minfo | mx | naptr | null | ptr | soa | spf | srv | txt |
    uid | uinfo | unspec | uri | wks
```

But what if we want to query an RR type that is not part of the list? Like DNSKEY or DS?

Well... the short answer is we get an error.

```elixir
iex(2)> :inet_res.resolve(~c"dahlheim.ch", :in, :dnskey)
** (CaseClauseError) no case clause matching: :dnskey
    (kernel 9.0.2) inet_dns.erl:396: :inet_dns.encode_type/1
    (kernel 9.0.2) inet_dns.erl:302: :inet_dns.encode_query_section/3
    (kernel 9.0.2) inet_dns.erl:275: :inet_dns.encode/1
    (kernel 9.0.2) inet_res.erl:694: :inet_res.make_query/5
    (kernel 9.0.2) inet_res.erl:657: :inet_res.make_query/4
    (kernel 9.0.2) inet_res.erl:628: :inet_res.res_query/5
    (kernel 9.0.2) inet_res.erl:148: :inet_res.resolve/5
    iex:33: (file)
```

The function `inet_dns.encode_type/1`, which is used internally by `:inet_res`, does not know how to map the `:dnskey` atom to the corresponding integer in the RR type table. Some might give up right here and chose to use `System.cmd` and `dig` because it just works, like we did when we first implemented our service.

Some might think, they have to implement their own DNS client using `gen_udp`.

Fortunately you don't have to do either of those things. But let's first delve a bit deeper into the behavior of the `:inet_res` module.

## Raw RR type IDs

One undocumented feature of the `:inet_res` module is that it allows you to pass the integer ID of the RR type directly instead of an atom.
For example in theory we could query the A record of the domain `dahlheim.ch` like this.

```elixir
iex(3)> :inet_res.resolve(~c"dahlheim.ch", :in, 1)
```

In cases where the RR types is supported it fetches the correct results but causes a `:noquery` error, because the RR type in the
answer header gets converted back to an atom and `inet_res.resolve` checks if the header of the question is equal to answer header.

```elixir
iex(3)> :inet_res.resolve(~c"dahlheim.ch", :in, 1)
{:error,
 {:noquery,
  {:dns_rec,
   {:dns_header, 2, true, :query, false, false, true, true, false, 0},
   [{:dns_query, ~c"dahlheim.ch", :a, :in, false}],
   [
     {:dns_rr, ~c"dahlheim.ch", :a, :in, 0, 8421, {149, 126, 4, 11}, :undefined,
      [], false}
   ], [], []}}}
```

But besides it being wrapped in a `:noquery` tuple the content of the answer is correct and we did not get an `CaseClauseError` error.
That is a big improvement.

{{< note >}}
If you use `inet_res.lookup/3` or any of the other `inet_res.lookup` arity function, it will return an empty list because it uses `:inet_res.resolve/5` under the hood and expects an `{:ok, dns_rec}` tuple.
{{< /note >}}

## Querying DNSKEY records

Now that we know that we can pass integers as query type instead of the atom, we can construct our new DNSKEY query, all that is missing is a quick lookup of the RR type ID of the DNSKEY type, which is 48.

Our new query will look like this:

```elixir
iex(4)> :inet_res.resolve(~c"dahlheim.ch", :in, 48)
```

And once we submit this query we get an `{:ok, dns_rec}` answer back, instead of the match error from before.

```elixir
iex(4)> :inet_res.resolve(~c"dahlheim.ch", :in, 48)
{:ok,
 {:dns_rec, {:dns_header, 3, true, :query, false, false, true, true, false, 0},
  [{:dns_query, ~c"dahlheim.ch", 48, :in, false}],
  [
    {:dns_rr, ~c"dahlheim.ch", 48, :in, 0, 75598,
     <<1, 0, 3, 13, 242, 30, 156, 252, 222, 57, 116, 223, 132, 191, 19, 155, 37,
       12, 64, 136, 235, 7, 131, 136, 123, 28, 153, 210, 101, 48, 230, 44, 0,
       176, 186, 246, ...>>, :undefined, [], false},
    {:dns_rr, ~c"dahlheim.ch", 48, :in, 0, 75598,
     <<1, 1, 3, 13, 10, 191, 218, 31, 120, 61, 229, 200, 246, 58, 127, 56, 155,
       139, 113, 10, 183, 53, 177, 21, 243, 105, 205, 47, 43, 139, 93, 124, 171,
       22, 121, ...>>, :undefined, [], false}
  ], [], []}}
  ```

Because `inet_res` still does not know anything about RR type 48 we get the raw binary back, also known as wire format. We have to write our own parser for DNSKEY records to turn ot into the more humany friendly presentation format. Thankfully pattern matching makes this trivial.

## Decoding the DNSKEY data

To decode the DNSKEY data from wire format to presentation format we first have to know the structure of the binary wire format
which is documented in [RFC 4034 Section 2.1](https://www.rfc-editor.org/rfc/rfc4034#section-2.1).

                         1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 3 3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |              Flags            |    Protocol   |   Algorithm   |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    /                                                               /
    /                            Public Key                         /
    /                                                               /
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

Most of the time a wire format diagram like this translates into a function head pattern match very nicely.
One way to represent this diagram in Elixir would be a function like this.

```elixir
defmodule DNSSEC do
  def dnskey_from_binary(<<flags::16, protocol::8, algorithm::8, public_key::binary>>) do
    :todo_presentation_format
  end
end
```

If you're unfamiliar with binary pattern matching, this pattern match uses the Shortcut Syntax.

What we are doing is telling Elixir to interpret the first 16 bits of the binary as one unsigned integer and assign it to a `flags` variable. Then we tell Elixir that the next 8 bits should also be interpreted as an unsigned integer, and the result should be assigned to the `protocol` variable. We do the same for the next 8 bits and assign them to the `algorithm` variable. Finally, we tell Elixir that the remaining bits of the binary should be assigned to the `public_key` variable without interpreting them.

Once we have the diffrent parts of the DNSKEY, we need to turn it into something we can read. The [Section 2.2](https://www.rfc-editor.org/rfc/rfc4034#section-2.2) of the RFC describes the presentation format of the DNSKEY.

I won't go into details because our pattern match already did most of the decoding for us, the only thing left for us to do is to base64 encode the `public_key` part.

Our final function will look like this.

```elixir
iex(5)> defmodule DNSSEC do
  def dnskey_from_binary(<<flags::16, protocol::8, algorithm::8, public_key::binary>>) do
    {flags, protocol, algorithm, Base.encode64(public_key)}
  end
end
```

We return the DNSKEY as a four element tuple to match the return types of the other RR types in `inet_res` like IPv4, IPv6 and MX, but we could have chosen a Struct or a Map as well.

Time to try it! We are going to use the `:inet_res.lookup/3` function because it makes piping the results to `Enum.map/2` easier.

```elixir
iex(6)> :inet_res.lookup(~c"dahlheim.ch", :in, 48) |> Enum.map(&DNSSEC.dnskey_from_binary/1)
[
  {256, 3, 13,
    "8h6c/N45dN+EvxObJQxAiOsHg4h7HJnSZTDmLACwuvbUC+BlZSCxI6AAgu3cfaeii4wXvUk7btuQKURQ3Cx7Qg=="},
  {257, 3, 13,
    "Cr/aH3g95cj2On84m4txCrc1sRXzac0vK4tdfKsWeW9QFVAwjf8Xj3hNhClhPGVPRxT6IlELtngJvQPA9HPDeg=="}
]
```

This looks much better don't you think? We can do the same for DS RR type and in the end our DNSSEC module will look similar to this.

```elixir
defmodule DNSSEC do
  def dnskey_from_binary(<<flags::16, protocol::8, algorithm::8, public_key::binary>>) do
    {flags, protocol, algorithm, Base.encode64(public_key)}
  end

  def ds_from_binary(<<type::16, algorithm::8, digest_type::8, digest::binary>>) do
    {type, algorithm, digest_type, Base.encode64(digest)}
  end
end
```

## Making it reusable

Although it's nice to know how to implement it yourself most of the time you probably just want to use a library.

I'm currently working on one that implements both DNSSEC and DS decoding as well as the keytag calculation function
needed to match a DNSKEY to an DS entry.

You can find it on my GitHub [hdahlheim/dnssec_ex](https://github.com/hdahlheim/dnssec_ex). There is a lot of work left to
allow us to fully validate DNSSEC in Elixir/Erlang, some of which needs to be done in Erlang/OTP itself.

My longtime goal is to contribute DNSSEC support to Erlang/OTP directly.
