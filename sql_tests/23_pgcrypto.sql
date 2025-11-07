create extension if not exists pgcrypto;

-- Symmetric encryption and decryption
select pgp_sym_encrypt('my_password', 'my_secret_key');
SELECT pgp_sym_decrypt('\xc30d0407030297f536f4fe44f31e6cd23c017c10dc49bf0045d0022f1769ea8d2e2ff77e489bf4a48d73764c381acdc5ac059f4e5f0e5b69ebc54e8b75328d21d6a56d7ab507e948e45606ebb8'::bytea, 'my_secret_key');

-- Generate 32-byte random key
SELECT gen_random_bytes(32);

--- Common encryption algorithms
select
 md5('database')  as c_md5 -- md5 encryption
,digest('database', 'sha1') as c_sha1 -- sha1 encryption
,encode(digest('database','SHA224'), 'hex') as c_SHA224 -- sha224 encryption
,encode(digest('database','SHA256'), 'hex') as c_SHA256 -- sha256 encryption
,encode(digest('database','SHA384'), 'hex') as c_SHA384 -- sha384 encryption
,encode(digest('database','SHA512'), 'hex') as c_SHA512 -- sha512 encryption
,pgp_sym_encrypt('database','secret_passphrase') as c_pgp_sym_encrypt -- symmetric encryption
,encrypt('123456','database','aes') as c_aes -- aes encryption
,encrypt('hashdata','database','3DES') as c_3des -- 3DES encryption
,encode(digest('database','sm3'), 'hex') as c_sm3 -- sm3 encryption
,gen_random_bytes(8) as c_random8 -- 8-byte random key
;