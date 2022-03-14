local bignum = require "jass.bignum"

local rsa = {}

-- RSA公钥
rsa.e = "010001"
rsa.n =
"00a41700d1ca6d3cd0f5138d9d48211542f6d48300ab3d99065407957d45693471ad003e071a59f7a4d3ac21d78f524a5c0fbcde1b881c2840c6d57754eb2152bd"

-- RSA私钥
local suc, key = pcall(require, '(ppk)')
rsa.d = suc and key


function rsa:init()
    if self.e then self.e_bn = bignum.new(bignum.bin(self.e)) end
    if self.n then self.n_bn = bignum.new(bignum.bin(self.n)) end
    if self.d then self.d_bn = bignum.new(bignum.bin(self.d)) end
end

-- 加密信息
-- @param 数字或字符串
function rsa:encrypt(c)
    local c_bn = bignum.new(c)
    local m_bn = c_bn:powmod(self.e_bn, self.n_bn)
    return tostring(m_bn)
end

-- 解密信息
-- @加密后的结果
function rsa:decrypt(m)
    local m_bn = bignum.new(m)
    local c_bn = m_bn:powmod(self.d_bn, self.n_bn)
    return tostring(c_bn)
end

rsa:init()

local sha1 = bignum.sha1

-- 生成签名
--	文本
function rsa:get_sign(content) return self:decrypt(sha1(content)) end

-- 验证签名
--	文本
--	签名
function rsa:check_sign(content, sign) return
    sha1(content) == self:encrypt(sign) end

return rsa
