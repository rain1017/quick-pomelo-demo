
local consts = require('app.consts')
local cardFormula = require('app.formula.cardFormula')

local ifTrueThen = function(cond, this, that)
    if cond then return this else return that end
end

TestCardFormula = {}

    function TestCardFormula:test_test()
        local self = this;
        local keyOfHandType = function(handType)
            local keys = table.keys(consts.card.handTypes);
            for i=1,#keys do
                if consts.card.handTypes[keys[i]] == handType then
                    return table.concat(table.mapnew(string.splitEx(string.lower(keys[i]), '_'), function(s)
                        return string.upper(string.sub(s, 1, 1)) .. string.sub(s, 2)
                    end), ' ');
                end
            end
            return 'UNKNOWN';
        end
        local assertType = function(hands, handType)
            table.mapnew(hands, function(cards)
                local _cards = string.splitEx(cards, '');
                local _handType = cardFormula.getHandType(_cards, true, true);
                printInfo('test cards: %s -> %s', cards, keyOfHandType(_handType));
                assertEquals(handType, _handType);
            end);
        end

        local assertInvalid = function(hands)
            table.mapnew(hands, function(cards)
                local _cards = string.splitEx(cards, '');
                local _handType = cardFormula.getHandType(_cards, true, true);
                printInfo('test cards: %s -> %s', cards, keyOfHandType(_handType));
                assertEquals(-1, _handType);
            end);
        end

        local assertGreater = function(handPairs)
            table.mapnew(handPairs, function(handPair)
                local cards, comp = handPair[1], handPair[2];
                local _cards, _compCards = string.splitEx(cards, ''), string.splitEx(comp, '');
                printInfo('compare cards: %s > %s', cards, comp);
                assertEquals(cardFormula.isCardsGreater(_cards, _compCards, true, true), true);
            end)
        end

        local assertNotGreater = function(handPairs)
            table.mapnew(handPairs, function(handPair)
                local cards, comp = handPair[1], handPair[2];
                local _cards, _compCards = string.splitEx(cards, ''), string.splitEx(comp, '');
                printInfo('compare cards: %s !> %s', cards, comp);
                assertEquals(cardFormula.isCardsGreater(_cards, _compCards, true, true), false);
            end);
        end


        assertType(
            {'XY'},
            consts.card.handTypes.ROCKET);
        assertType(
            {'AAAA', 'JJJJ', '2222', '0000', '5555'},
            consts.card.handTypes.BOMB);
        assertType(
            {'3', '4', '8', '9', 'Q'},
            consts.card.handTypes.SOLO);
        assertType(
            {'33', '44', '88', '99', 'QQ', '22'},
            consts.card.handTypes.PAIR);
        assertType(
            {'34567', '0JQKA', '3456789'},
            consts.card.handTypes.STRAIGHT);
        assertType(
            {'334455', '445566', '77889900', '9900JJ', 'QQKKAA'},
            consts.card.handTypes.CONSECUTIVE_PAIRS);
        assertType(
            {'333', '444', '888', '999', 'QQQ', '222'},
            consts.card.handTypes.TRIO);
        assertType(
            {'3334', '3444', '4888', '9990', 'JQQQ', 'A222'},
            consts.card.handTypes.TRIO_SOLO);
        assertType(
            {'33344', '33444', '44888', '99900', 'JJQQQ', 'AA222'},
            consts.card.handTypes.TRIO_PAIR);
        assertType(
            {'333444', '444555', '777888', '999000', 'JJJQQQ', 'KKKAAA'},
            consts.card.handTypes.AIRPLANE);
        assertType(
            {'333444XY', '4445552X', '888999JA', '999000KK', '3QQQKKKA'},
            consts.card.handTypes.AIRPLANE_SOLO);
        assertType(
            {'3334445566', '3344455566', '4488899922', '999000AA22', '00JJJQQQKK', '00KKKAAA22'},
            consts.card.handTypes.AIRPLANE_PAIR);
        assertType(
            {'333345', '334444', '8888KX', '999922', '5QQQQK', '2222XY'},
            consts.card.handTypes.SPACE_SHUTTLE_SOLO);
        assertType(
            {'33334455', '33444466', '33448888', '999900KK', 'JJQQQQ22', '55AA2222'},
            consts.card.handTypes.SPACE_SHUTTLE_PAIR);

        assertInvalid({
            '2345', '234', '345', 'A23', 'KKAA22', '23444', '3AAA222X', 'AAA222',
            'QKA2X'
        });

        assertGreater({
            {'2', 'A'},
            {'Y', 'X'},
            {'Y', 'J'},
            {'44', '33'},
            {'22', 'AA'},
            {'45678', '34567'},
            {'QQKKAA', '445566'},
            {'QQQ', '444'},
            {'3QQQ', '4443'},
            {'33QQQ', '44433'},
            {'33QQQKKK', '000JJJ2X'},
            {'3344QQQKKK', '000JJJAA22'},
            {'344445', '333344'},
            {'33444455', '33334455'},
            {'5555', '4444'},
            {'2222', '4444'},
            {'XY', '4444'},
        });
        assertNotGreater({
            {'456789', '34567'},
            {'2', 'AA'},
            {'33', '22'},
        });

        assertTrue(cardFormula.getHandType({'02', '12', '03', '32'}), consts.card.handTypes.TRIO_SOLO);

    end


