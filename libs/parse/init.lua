
--// Create the base Parser class
local Parser = {
    tokens = {}
}
Parser.__index = Parser

--// Get the modules for the parser
local InvalidSyntaxError = require('libs.dc.error.InvalidSyntaxError')
local BinOp = require('libs.parse.node.BinOp')
local UnOp = require('libs.parse.node.UnOp')
local Number = require('libs.parse.node.Number')
require('libs.consts')
require('libs.rebind')

--// Create a new parser instance
function Parser.new(tokens)
    local self = setmetatable({}, Parser)

    self.tokens = tokens
    self.currentTokenIdx = 0
    self.currentToken = nil

    self:Advance()

    return self
end

--// Movement between the tokens in the parser
function Parser:Advance()
    self.currentTokenIdx = self.currentTokenIdx + 1
    self.currentToken = self.tokens[self.currentTokenIdx] or nil
end

--// Create a BinOp token
function Parser:GenerateBinOp(func, operators)
    local left = self[func](self)

    while self.currentToken ~= nil and table.find(operators, self.currentToken.tokenType) do
        local operator = self.currentToken
        self:Advance()
        local right = self[func](self)
        left = BinOp.new(left, operator, right):SetPosition(operator.position)
    end

    return left
end

--// Order of operations
function Parser:Factor()
    local token = self.currentToken

    if token and token.tokenType == TokenType.TT_NUMBER then
        self:Advance()
        return Number.new(token):SetPosition(token.position)
    end
end
function Parser:Paren()
    if self.currentToken.tokenType == TokenType.TT_LPAREN then
        self:Advance()
        local res = self:GenerateBinOp("Expression", {TokenType.TT_ADD, TokenType.TT_SUB})
        self:Advance()
        return res
    else
        return self:Factor()
    end
end
function Parser:Atom()
    return self:GenerateBinOp("Paren", {TokenType.TT_POW})
end
function Parser:Term()
    return self:GenerateBinOp("Atom", {TokenType.TT_MUL, TokenType.TT_DIV})
end
function Parser:Expression()
    return self:GenerateBinOp("Term", {TokenType.TT_ADD, TokenType.TT_SUB})
end

--// Parse the tokens
function Parser:Parse()

    local res = self:Expression()
    if typeof(res) == "Error" then
        return nil, res
    end
    return res, nil

end

--// Return the module
return Parser
