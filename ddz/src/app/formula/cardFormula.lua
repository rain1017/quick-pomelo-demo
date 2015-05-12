local consts = require('app.consts')

table.mapnew = function(t, fn)
    local newt = {}
    for k,v in pairs(t) do
        newt[k] = fn(v)
    end
    return newt
end

string.splitEx = function(input, delimiter)
    local ret = {}
    if delimiter == '' then
        for i=1,string.len(input) do
            ret[#ret+1] = string.sub(input, i, i)
        end
        return ret
    end
    return string.split(input, delimiter)
end

local ifTrueThen = function(cond, this, that)
    if cond then return this else return that end
end

local exp = {}

exp.unpackCards = function(cards)
    local unpacked = {}
    for i,v in ipairs(cards) do
        local point = string.sub(v, 2)
        if point == 'X' or point == 'Y' then return {consts.card.suit.joker, point} end
        if point == '0' then point = '10' end
        unpacked[i] = {tonumber(string.sub(v, 1, 1)), point}
    end
    return unpacked
end

exp.unpackCard = function(card)
    local point = string.sub(card, 2)
    if point == '0' then point = '10' end
    return {tonumber(string.sub(card, 1, 1)), point}
end

exp.packCard = function(suit, point)
    if point == 'X' then return point end
    if point == 'Y' then return point end
    if point == '10' then point = '0' end
    return suit .. point
end

exp._toPointIdx = function(c, isPoint)
    local p = ifTrueThen(isPoint, c, string.sub(c, 2)) --c.substring(1);
    if p == consts.card.joker then
        return #consts.card.points + 1;
    elseif p == consts.card.jokerRed then
        return #consts.card.points + 2;
    else
        return table.keyof(consts.card.points, p) -- _.indexOf(consts.card.points, p);
    end
end

exp.sortCards = function(cards, isPoint)
    table.sort(cards, function(c1, c2)
        local p1 = exp._toPointIdx(c1, isPoint);
        local p2 = exp._toPointIdx(c2, isPoint);
        if p1 == p2 and not isPoint then return tonumber(string.sub(c1, 1, 1)) < tonumber(string.sub(c2, 1, 1)) end
        return p1 < p2
    end);
    return cards
end

exp.isCardsValid = function(cards, isPoint, sorted)
    local res = exp.getHandType(cards, isPoint, sorted) ~= -1;
    --printInfo('exp.isCardsValid: cards=%s, isPoint=%s, sorted=%s, res=%s', json.encode(cards), isPoint, sorted, res);
    return res;
end

exp.isCardsGreater = function(cards, compared, isPoint, sorted)
    --printInfo('cards: %s, compared: %s', json.encode(cards), json.encode(compared));
    local handInfo = exp.getHandTypeInfo(cards, isPoint, sorted);
    local compHandInfo = exp.getHandTypeInfo(compared, isPoint, sorted);
    if not handInfo or not compHandInfo then return false end
    --printInfo('handInfo: %s, compHandInfo: %s', json.encode(handInfo), json.encode(compHandInfo));
    if handInfo.type == consts.card.handTypes.ROCKET then
        return true;
    end
    if compHandInfo.type == consts.card.handTypes.ROCKET then
        return false;
    end
    if handInfo.type == consts.card.handTypes.BOMB and
        compHandInfo.type ~= consts.card.handTypes.BOMB then
        return true;
    end
    if handInfo.type ~= compHandInfo.type then
        return false;
    end
    if handInfo.info.required and
        handInfo.info.required ~= compHandInfo.info.required then
        return false;
    end
    return handInfo.info.main > compHandInfo.info.main;
end

local handTypes = table.keys(consts.card.handTypes);
local handFuncNames = table.mapnew(handTypes, function(t)
        return 'isHand' .. table.concat(table.mapnew(string.splitEx(string.lower(t), '_'), function(s)
            return string.upper(string.sub(s, 1, 1)) .. string.sub(s, 2)
        end))
    end);
exp.getHandType = function(cards, isPoint, sorted)
    for i,v in pairs(handTypes) do
        if exp[handFuncNames[i]](cards, isPoint, sorted) then
            return consts.card.handTypes[handTypes[i]];
        end
    end
    return -1;
end

exp.getHandTypeInfo = function(cards, isPoint, sorted)
    for i,v in pairs(handTypes) do
        local info = exp[handFuncNames[i]](cards, isPoint, sorted);
        if info then
            return {type = consts.card.handTypes[handTypes[i]], info = info};
        end
    end
    return nil;
end

exp.isHandRocket = function(cards, isPoint, sorted)
    if #cards ~= 2 then
        return false;
    end
    local ps = ifTrueThen(isPoint, cards, table.mapnew(cards, function(c) return string.sub(c, 2) end))
    if (ps[1] == consts.card.joker and ps[2] == consts.card.jokerRed) or
        (ps[2] == consts.card.joker and ps[1] == consts.card.jokerRed) then
        return {main = exp._toPointIdx(cards[#cards], isPoint)};
    end
    return false;
end

exp.isHandBomb = function(cards, isPoint, sorted)
    if #cards ~= 4 then
        return false;
    end
    local ps = ifTrueThen(isPoint, cards, table.mapnew(cards, function(c) return string.sub(c, 2) end));
    if ps[2] == ps[1] and ps[3] == ps[1] and ps[4] == ps[1] then
        return {main = exp._toPointIdx(ps[1], true)};
    end
    return false;
end

exp.isHandSolo = function(cards, isPoint, sorted)
    if #cards ~= 1 then
        return false;
    end
    return {main = exp._toPointIdx(cards[1], isPoint)};
end

exp.isHandPair = function(cards, isPoint, sorted)
    if #cards ~= 2 then
        return false;
    end
    local ps = ifTrueThen(isPoint, cards, table.mapnew(cards, function(c) return string.sub(c, 2) end));
    if ps[2] == ps[1] then
        return {main = exp._toPointIdx(ps[1], true)};
    end
    return false;
end

exp.isHandStraight = function(cards, isPoint, sorted)
    if #cards < 5 then
        return false;
    end
    local ps = ifTrueThen(isPoint, cards, table.mapnew(cards, function(c) return string.sub(c, 2) end));
    ps = ifTrueThen(sorted, ps, exp.sortCards(ps, true));
    local idxs = table.mapnew(ps, function(p) return exp._toPointIdx(p, true) end);
    for i=2,#idxs do
        if idxs[i] ~= idxs[i-1] + 1 then
            return false;
        end
    end
    if idxs[#idxs] >= #consts.card.points then
        return false;
    end
    return {main = idxs[#idxs], required = #cards};
end



exp.isHandConsecutivePairs = function(cards, isPoint, sorted)
    if #cards < 6 or math.fmod(#cards, 2) ~= 0 then
        return false;
    end
    local ps = ifTrueThen(isPoint, cards, table.mapnew(cards, function(c) return string.sub(c, 2) end))
    ps = ifTrueThen(sorted, ps, exp.sortCards(ps, true));
    if table.keyof({'2', consts.card.joker, consts.card.jokerRed}, ps[#ps]) ~= nil then
        return false;
    end
    for i=0,#ps/2-1 do
        if ps[i*2+1] ~= ps[i*2+2] then
            return false;
        end
        if i > 0 and exp._toPointIdx(ps[i*2], true) + 1 ~= exp._toPointIdx(ps[i*2+1], true) then
            return false;
        end
    end
    return {main = exp._toPointIdx(ps[#ps], true), required = #cards/2};
end

exp.isHandTrio = function(cards, isPoint, sorted)
    if #cards ~= 3 then
        return false;
    end
    local ps = ifTrueThen(isPoint, cards, table.mapnew(cards, function(c) return string.sub(c, 2) end))
    if ps[2] == ps[1] and ps[3] == ps[1] then
        return {main = exp._toPointIdx(ps[1], true)};
    end
    return false;
end

exp.isHandTrioSolo = function(cards, isPoint, sorted)
    if #cards ~= 4 then
        return false;
    end
    local ps = ifTrueThen(isPoint, cards, table.mapnew(cards, function(c) return string.sub(c, 2) end))
    printInfo(json.encode(ps))
    ps = ifTrueThen(sorted, ps, exp.sortCards(ps, true));
    if ifTrueThen(ps[2] == ps[1], (ps[3] == ps[1] and ps[4] ~= ps[1]), (ps[3] == ps[2] and ps[4] == ps[2])) then
        return {main = exp._toPointIdx(ps[2], true)};
    end
    return false;
end


exp.isHandTrioPair = function(cards, isPoint, sorted)
    if #cards ~= 5 then
        return false;
    end
    local ps = ifTrueThen(isPoint, cards, table.mapnew(cards, function(c) return string.sub(c, 2) end))
    ps = ifTrueThen(sorted, ps, exp.sortCards(ps, true));
    if ifTrueThen(ps[3] == ps[2], (ps[1] == ps[2] and ps[5] == ps[4] and ps[4] ~= ps[3]),
        (ps[1] == ps[2] and ps[4] == ps[3] and ps[5] == ps[3])) then
        return {main = exp._toPointIdx(ps[3], true)};
    end
    return false;
end

exp.isHandAirplane = function(cards, isPoint, sorted)
    if #cards < 6 or math.fmod(#cards, 3) ~= 0 then
        return false;
    end
    local ps = ifTrueThen(isPoint, cards, table.mapnew(cards, function(c) return string.sub(c, 2) end))
    ps = ifTrueThen(sorted, ps, exp.sortCards(ps, true));
    for i=0,#ps/3-1 do
        if ps[i*3+2+1] ~= ps[i*3+1] or ps[i*3+1+1] ~= ps[i*3+1] then
            return false;
        end
        if i > 0 and exp._toPointIdx(ps[i*3-1+1], true) + 1 ~= exp._toPointIdx(ps[i*3+1], true) then
            return false;
        end
    end
    if ps[#ps] == '2' then
        return false;
    end
    return {main = exp._toPointIdx(ps[#ps], true), required = #cards/3};
end

exp.isHandAirplaneSolo = function(cards, isPoint, sorted)
    if #cards < 8 or math.fmod(#cards, 4) ~= 0 then
        return false;
    end
    local ps = ifTrueThen(isPoint, cards, table.mapnew(cards, function(c) return string.sub(c, 2) end))
    ps = ifTrueThen(sorted, ps, exp.sortCards(ps, true));
    local trios = {};
    for i=3,#ps do
        if ps[i] == ps[i-2] and ps[i-1] == ps[i-2] then
            if table.keyof(trios, ps[i]) == nil then
                trios[#trios+1] = ps[i]
            end
        end
    end
    if #trios < 2 then
        return false;
    end
    if trios[#trios] == '2' then
        return false;
    end
    local trioIdxs = table.mapnew(trios, function(p) return exp._toPointIdx(p, true) end);
    for i=2,#trioIdxs do
        if trioIdxs[i] ~= trioIdxs[i-1] + 1 then
            return false;
        end
    end
    return {main = trioIdxs[#trioIdxs], required = #cards/4};
end

exp.isHandAirplanePair = function(cards, isPoint, sorted)
    if #cards < 10 or math.fmod(#cards, 5) ~= 0 then
        return false;
    end
    local ps = ifTrueThen(isPoint, cards, table.mapnew(cards, function(c) return string.sub(c, 2) end))
    ps = ifTrueThen(sorted, ps, exp.sortCards(ps, true));
    local trios = {};
    for i=3,#ps do
        if ps[i] == ps[i-2] and ps[i-1] == ps[i-2] then
            if table.keyof(trios, ps[i]) == nil then
                trios[#trios+1] = ps[i]
            end
        end
    end
    if #trios < 2 then
        return false;
    end
    if trios[#trios] == '2' then
        return false;
    end
    local trioIdxs = table.mapnew(trios, function(p) return exp._toPointIdx(p, true) end);
    for i=2,#trioIdxs do
        if trioIdxs[i] ~= trioIdxs[i-1] + 1 then
            return false;
        end
    end
    local pairs = {};
    for i=1,#ps do
        if table.keyof(trios, ps[i]) == nil then
            pairs[#pairs+1] = ps[i]
        end
    end
    if exp._isPairs(pairs) then
        return {main = trioIdxs[#trioIdxs], required = #cards/5};
    end
    return false;
end

exp.isHandSpaceShuttleSolo = function(cards, isPoint, sorted)
    if #cards ~= 6 then
        return false;
    end
    local ps = ifTrueThen(isPoint, cards, table.mapnew(cards, function(c) return string.sub(c, 2) end))
    ps = ifTrueThen(sorted, ps, exp.sortCards(ps, true));
    local fours = {};
    for i=4,#ps do
        if ps[i] == ps[i-3] and ps[i-1] == ps[i-3] and ps[i-2] == ps[i-3] then
            if table.keyof(fours, ps[i]) == nil then
                fours[#fours+1] = ps[i]
            end
        end
    end
    if #fours < 1 then
        return false;
    end
    return {main = exp._toPointIdx(fours[#fours], true)};
end

exp._isPairs = function(pairs)
    if math.fmod(#pairs, 2) ~= 0 then
        return false;
    end
    for i=0,#pairs/2-1 do
        if pairs[i*2+1] ~= pairs[i*2+2] then
            return false;
        end
    end
    return true;
end

exp.isHandSpaceShuttlePair = function(cards, isPoint, sorted)
    if #cards ~=8 then
        return false;
    end
    local ps = ifTrueThen(isPoint, cards, table.mapnew(cards, function(c) return string.sub(c, 2) end))
    ps = ifTrueThen(sorted, ps, exp.sortCards(ps, true));
    local fours = {};
    for i=4,#ps do
        if ps[i] == ps[i-3] and ps[i-1] == ps[i-3] and ps[i-2] == ps[i-3] then
            if table.keyof(fours, ps[i]) == nil then
                fours[#fours+1] = ps[i]
            end
        end
    end
    if #fours < 1 then
        return false;
    end
    local pairs = {};
    for i=1,#ps do
        if table.keyof(fours, ps[i]) == nil then
            pairs[#pairs+1] = ps[i]
        end
    end
    if exp._isPairs(pairs) then
        return {main = exp._toPointIdx(fours[#fours], true)};
    end
    return false;
end


return exp