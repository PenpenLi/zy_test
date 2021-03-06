local M = {}

local inTrig = function(p, tri)
    local a,b,c = tri[1], tri[2], tri[3]

    local signOfTrig = (b.x - a.x)*(c.y - a.y) - (b.y - a.y)*(c.x - a.x);
    local signOfAB = (b.x - a.x)*(p.y - a.y) - (b.y - a.y)*(p.x - a.x);
    local signOfCA = (a.x - c.x)*(p.y - c.y) - (a.y - c.y)*(p.x - c.x);
    local signOfBC = (c.x - b.x)*(p.y - c.y) - (c.y - b.y)*(p.x - c.x);

    local d1 = ((signOfAB * signOfTrig) >= 0);
    local d2 = ((signOfCA * signOfTrig) >= 0);
    local d3 = ((signOfBC * signOfTrig) >= 0);
    return d1 and d2 and d3;
end

local inMultiShape = function(p, multiShape)
    assert(#multiShape>2, "multiShape 必须有3个以上的点")
    for i = 3, #multiShape do
        if(inTrig(p, {multiShape[1],multiShape[i-1],multiShape[i]})) then
            return true
        end
    end
    return false
end

local function getTriArea(tri)
    -- dump(tri)
    local a = cc.pGetDistance(tri[1], tri[2])
    local b = cc.pGetDistance(tri[2], tri[3])
    local c = cc.pGetDistance(tri[3], tri[1])
    -- print(a,b,c)
    local p = (a+b+c)/2
    local s = math.sqrt(p*(p-a)*(p-b)*(p-c))
    return s
end

-- 从multShape得到一个随机的点
local function getRandomPositionByTri(tri)

    local ab = cc.pSub(tri[2], tri[1])
    local ac = cc.pSub(tri[3], tri[1])
    local x = math.random()
    local y = math.random()
    if((x+y) > 1) then
        x =  1-x
        y =  1-y
    end

    local p = cc.pAdd(tri[1], cc.pAdd(cc.pMul(ab, x), cc.pMul(ac, y)))
    return p
end

local function getRandomPositionByMulti(multiShape)
    local sAreaTbl = {}
    local sum = 0
    local proTbl = {}
    for i = 3, #multiShape do
        sAreaTbl[#sAreaTbl + 1] = getTriArea({multiShape[1],multiShape[i-1],multiShape[i]})
        sum = sum + sAreaTbl[#sAreaTbl]
    end
    local r = math.random()
    for i = 1, #sAreaTbl do
        proTbl[i] = sAreaTbl[i]/sum
        if i >= 2 then
            proTbl[i] = proTbl[i] + proTbl[i-1]
        end
        if r <= proTbl[i] then
            return getRandomPositionByTri({multiShape[1],multiShape[i+1],multiShape[i+2]})
        end
    end
end

-- 测试不规则形状的点击事件
function M:testIrregularShapeClickEvent()
    local layer = test:createGLtestLayer()
    local sprName = "#baccarat_road_small_road_bg.png"
	local bg = display.newScale9Sprite(sprName, display.width/2, display.height/2, cc.size(100,100))
        :addTo(layer):setColor(cc.c3b(255,0,0))
    local clickShapeArea = {cc.p(0,0), cc.p(100,0), cc.p(50,100),cc.p(0,100)}
    local clickShapeArea2 = {cc.p(0,0), cc.p(100,0), cc.p(50,100)}
    bg:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event) 
        if event.name == "began" then
            self.isClicked = true
            self._preX = event.x
            self._preY = event.y
            local clickPos = bg:convertToNodeSpace(cc.p(event.x, event.y))
            local isClicked = inMultiShape(clickPos, clickShapeArea)
            self.isClicked = isClicked            
        elseif event.name == "moved" then
            if self.isClicked then
                print("moved")
            end
        elseif event.name == "ended" then
            if self.isClicked then
                print("ended")
            end
        end
    end)
    bg:setTouchEnabled(true)
    bg:setNodeEventEnabled(true)

    --颜色必须用浮点型来使用 不然没有效果
    local drawNode = cc.DrawNode:create();
    drawNode:setPosition(cc.p(0,0))
    drawNode:setAnchorPoint(0,0)
    drawNode:drawPolygon(clickShapeArea, {fillColor = cc.c4f(1,0,1,1)})
    bg:addChild(drawNode)
    for i = 1, 200 do
        local rp = getRandomPositionByMulti(clickShapeArea)
        drawNode:drawDot(rp, 4,  cc.c4f(0,0,1,1))
    end
end

function checkPointInCircle(p1, p2, r)
    local length = cc.pGetDistance(p1, p2)
    -- print(length)
    return length <= r
end

-- 判断tarPos 筹码被盖住了
function checkInCover(tarPos, posTbl, r)
    local xTbl = {tarPos.x + r, tarPos.x + r/2, tarPos.x , tarPos.x- r/2, tarPos.x - r}
    local yTbl = {tarPos.y + r, tarPos.y + r/2, tarPos.y , tarPos.y- r/2, tarPos.y + r}
    local pTbl = {}
    for i, v1 in ipairs(xTbl) do
        for j, v2 in ipairs(yTbl) do
            pTbl[#pTbl + 1] = cc.p(v1, v2)
        end
    end
    local cnt = 0
    for i, v in ipairs(pTbl) do
        for _, v2 in ipairs(posTbl) do
            if checkPointInCircle(v, v2, r) then
                print(v.x, v.y, "in circle", v2.x, v2.y)
                cnt = cnt + 1
                break
            end
        end
    end
end

-- 得到tarPos 半径2r范围内 所有的 位置
function getPosTblInPosArea(tarPos, posTbl, r)
    local retTbl = {}
    for _, v2 in ipairs(posTbl) do
        if checkPointInCircle(tarPos, v2, 2*r) then
            retTbl[#retTbl + 1] = v2
        end
    end
    return retTbl
end

function M:testCircle()   
    local layer = test:createGLtestLayer()
    -- local sprName = "#baccarat_road_small_road_bg.png"
	-- local bg = display.newScale9Sprite(sprName, display.width/2, display.height/2, cc.size(100,100))
    --     :addTo(layer):setColor(cc.c3b(255,0,0))
    -- --颜色必须用浮点型来使用 不然没有效果
    local drawNode = cc.DrawNode:create();
    drawNode:setPosition(cc.p(0,0))
    drawNode:setAnchorPoint(0,0)
    layer:addChild(drawNode)
    local r = 20
    local targetPos = cc.p(100,100)
    drawNode:drawDot(targetPos, r,  cc.c4f(0,0,1,1))
    local posTbl = {}
    for i = 1, 200 do
        local p1 = math.random() * display.width/2
        local p2 = math.random() * display.height/2
        posTbl[#posTbl + 1] = cc.p(p1,p2)
        drawNode:drawDot(posTbl[#posTbl], r,  cc.c4f(1,0,1,1))
    end
    checkInCover(targetPos, posTbl, r)
end

return M