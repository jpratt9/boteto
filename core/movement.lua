--[[
    Movement Module
    BANETO movement code copied TO THE LETTER
]]

local Movement = {}

-- ============================================
-- MOVEMENT START/STOP FUNCTIONS (BANETO EXACT)
-- ============================================

function Movement.MoveForwardStart()
    MoveForwardStart()
end

function Movement.MoveForwardStop()
    MoveForwardStop()
end

function Movement.MoveBackwardStart()
    MoveBackwardStart()
end

function Movement.MoveBackwardStop()
    MoveBackwardStop()
end

function Movement.StopMovement()
    if not _G.BOTETO_MOVEMENTSTOPDELAYTIME or GetTime() > _G.BOTETO_MOVEMENTSTOPDELAYTIME then
        _G.BOTETO_MOVEMENTSTOPDELAYTIME = GetTime()+0.15

        MoveForwardStop()
        StrafeLeftStop()

        if not UnitCastingInfo("player") and not UnitChannelInfo("player") and 0 < GetUnitSpeed("player") then
            Movement.MoveBackwardStart()
        end
        Movement.MoveBackwardStop()
    end
end

-- ============================================
-- FACING FUNCTIONS (BANETO EXACT)
-- ============================================

function Movement.GetFacingValue(xMob,yMob,zMob)
    if xMob and yMob and zMob then
        local xPla, yPla, zPla = ObjectPosition("player")
        if xPla then
            local a = yMob - yPla
            local b = xMob - xPla

            if a < 0 and b > 0 then
                local value = ((270 + math.atan(b/-a)*180/math.pi)/360)*(2*math.pi)
                return value
            elseif a < 0 and b < 0 then
                local value = ((270 - math.atan(b/a)*180/math.pi)/360)*(2*math.pi)
                return value
            elseif a > 0 and b < 0 then
                local value = ((90 + math.atan(-b/a)*180/math.pi)/360)*(2*math.pi)
                return value
            elseif a > 0 and b > 0 then
                local value = ((90 - math.atan(b/a)*180/math.pi)/360)*(2*math.pi)
                return value
            end
        end
    end
end

function Movement.FaceTarget(target)
    if target then
        local tx, ty, tz = ObjectPosition(target)
        if tx then
            local angle = Movement.GetFacingValue(tx, ty, tz)
            if angle then
                FaceDirection(angle, true)
            end
        end
    end
end

function Movement.FaceDirection(angle)
    if angle then
        FaceDirection(angle, true)
    end
end

-- ============================================
-- DISTANCE CALCULATION (BANETO EXACT)
-- ============================================

function Movement.GetDistance3D(X, Y, Z, XX, YY, ZZ)
    local dist;
    if X and XX and Y and YY and Z and ZZ then
        dist = math.sqrt((X-XX)*(X-XX) + (Y-YY)*(Y-YY) + (Z-ZZ)*(Z-ZZ))
        if dist == nil then
            dist = 0
        end
        if (dist < 0 and dist > 0) then
            print("[Movement] DISTANCE CALC ERROR -NAND!!!!!!!")
            return 0
        end
        return dist
    end
end

-- ============================================
-- PATHFINDING (BANETO PATTERN - SIMPLIFIED)
-- ============================================

function Movement.MeshTo(x, y, z)
    if not x or not y or not z then
        print("[Movement] MeshTo: Invalid coordinates")
        return false
    end

    if x == 0 and y == 0 and z == 0 then
        print("[Movement] MeshTo: 0,0,0 coordinates")
        Movement.StopMovement()
        return false
    end

    -- Get player position
    local px, py, pz = ObjectPosition("player")
    if not px then
        print("[Movement] MeshTo: Could not get player position")
        return false
    end

    -- Calculate distance to destination
    local dist = Movement.GetDistance3D(px, py, pz, x, y, z)

    -- If very close (< 2 yards), we're done
    if dist and dist < 2 then
        Movement.StopMovement()
        return true
    end

    -- Face the destination CONTINUOUSLY with throttling (BANETO pattern)
    local angle = Movement.GetFacingValue(x, y, z)
    if angle then
        -- Throttle FaceDirection calls (every 0.1s)
        if not _G.BOTETO_MESHTO_FACE_DELAY or GetTime() > _G.BOTETO_MESHTO_FACE_DELAY then
            local currentAngle = GetPlayerFacing() or 0
            local angleDiff = math.abs(currentAngle - angle)

            -- Only update if difference is significant
            if angleDiff > 0.05 then
                Movement.FaceDirection(angle)
            end

            _G.BOTETO_MESHTO_FACE_DELAY = GetTime() + 0.1
        end

        -- Only move forward if facing roughly correct direction
        local currentAngle = GetPlayerFacing() or 0
        local angleDiff = math.abs(currentAngle - angle)
        if angleDiff < 0.4 or angleDiff > 5.9 then  -- ~23 degrees tolerance
            Movement.MoveForwardStart()
        end
    end

    return false -- Still moving
end

-- ============================================
-- PLAYER POSITION CHECK (BANETO EXACT)
-- ============================================

function Movement.PlayerPosition(x, y, z, radius)
    if not x or not y or not z or not radius then
        return false
    end

    local px, py, pz = ObjectPosition("player")
    if not px then
        return false
    end

    local dist = Movement.GetDistance3D(px, py, pz, x, y, z)

    return dist and dist <= radius
end

return Movement
