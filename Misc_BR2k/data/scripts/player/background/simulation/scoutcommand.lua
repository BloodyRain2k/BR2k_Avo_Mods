function ScoutCommand:revealSectors(ratio)
    local specs = SectorSpecifics()
    local seed = GameSeed()
    local faction = getParentFaction()
    local gatesMap = GatesMap(GameSeed())


    local entry = ShipDatabaseEntry(faction.index, self.shipName)
    local captain = entry:getCaptain()
    local captainNoteTemplate = "${captainNote} ${captainName}"%_T
    local captainNote = "Uncovered by captain"%_T

    local revealOffgridSectors = true
    local offgridSectorsToReveal = {}

    local captainIsExplorer = captain:hasClass(CaptainUtility.ClassType.Explorer)

    if captainIsExplorer then
        revealOffgridSectors = true
        local specialNoteLines =
        {
            "There is something abnormal and possibly dangerous here."%_t,
            "I have not seen anything like this before. Caution!"%_t,
            "There is something strange in this sector. Be careful!"%_t,
        }
        offgridSectorsToReveal["sectors/ancientgates"] = specialNoteLines
        offgridSectorsToReveal["sectors/asteroidshieldboss"] = specialNoteLines
        offgridSectorsToReveal["sectors/cultists"] = specialNoteLines
        offgridSectorsToReveal["sectors/lonewormhole"] = specialNoteLines
        offgridSectorsToReveal["sectors/researchsatellite"] = specialNoteLines
        offgridSectorsToReveal["sectors/resistancecell"] = specialNoteLines
        offgridSectorsToReveal["sectors/teleporter"] = specialNoteLines

        local containerNoteLines =
        {
            "Containers are stored in this sector."%_t,
            "We found a container field in this sector."%_t,
            "There is a container field in this sector."%_t,
        }
        offgridSectorsToReveal["sectors/containerfield"] = containerNoteLines
        offgridSectorsToReveal["sectors/massivecontainerfield"] = containerNoteLines
    end

    if captainIsExplorer or captain:hasClass(CaptainUtility.ClassType.Smuggler) then
        revealOffgridSectors = true
        local smugglerNoteLines =
        {
            "Smugglers hide here."%_t,
            "There are smugglers hanging around here."%_t,
            "Smugglers use this sector as their hideout."%_t,
        }
        offgridSectorsToReveal["sectors/smugglerhideout"] = smugglerNoteLines
    end

    if captainIsExplorer or captain:hasClass(CaptainUtility.ClassType.Miner) then
        revealOffgridSectors = true
        local asteroidNoteLines =
        {
            "There are asteroids here."%_t,
            "We found an asteroid field in this sector."%_t,
            "We found asteroids here."%_t,
            "There are asteroids in this sector."%_t,
        }
        offgridSectorsToReveal["sectors/asteroidfield"] = asteroidNoteLines
        offgridSectorsToReveal["sectors/pirateasteroidfield"] = asteroidNoteLines
        offgridSectorsToReveal["sectors/defenderasteroidfield"] = asteroidNoteLines
        offgridSectorsToReveal["sectors/asteroidfieldminer"] = asteroidNoteLines
        offgridSectorsToReveal["sectors/smallasteroidfield"] = asteroidNoteLines
        offgridSectorsToReveal["sectors/wreckageasteroidfield"] = asteroidNoteLines
    end

    if captainIsExplorer or captain:hasClass(CaptainUtility.ClassType.Scavenger) then
        revealOffgridSectors = true
        local wreckageNoteLines =
        {
            "There are wrecks in this sector."%_t,
            "We found wrecks in this sector."%_t,
            "This sector contains wrecks."%_t,
        }
        offgridSectorsToReveal["sectors/functionalwreckage"] = wreckageNoteLines
        offgridSectorsToReveal["sectors/stationwreckage"] = wreckageNoteLines
        offgridSectorsToReveal["sectors/wreckageasteroidfield"] = wreckageNoteLines
        offgridSectorsToReveal["sectors/wreckagefield"] = wreckageNoteLines
    end

    if captainIsExplorer or captain:hasClass(CaptainUtility.ClassType.Daredevil) then
        revealOffgridSectors = true
        local pirateNoteLines =
        {
            "There are pirates hiding here."%_t,
            "We saw pirates in this sector."%_t,
            "This sector is infested with pirates."%_t,
        }
        offgridSectorsToReveal["sectors/pirateasteroidfield"] = pirateNoteLines
        offgridSectorsToReveal["sectors/piratefight"] = pirateNoteLines
        offgridSectorsToReveal["sectors/piratestation"] = pirateNoteLines

        local xsotanNoteLines =
        {
            "There are Xsotan here."%_t,
            "We saw Xsotan in this sector."%_t,
            "Don't go here if you don't like Xsotan."%_t,
        }
        offgridSectorsToReveal["sectors/xsotanasteroids"] = xsotanNoteLines
        offgridSectorsToReveal["sectors/xsotantransformed"] = xsotanNoteLines
        offgridSectorsToReveal["sectors/xsotanbreeders"] = xsotanNoteLines
    end

    local sectorsToReveal = {}

    for _, coords in pairs(self.area.analysis.reachableCoordinates) do
        local x = coords.x
        local y = coords.y
        local regular, offgrid = specs.determineFastContent(x, y, seed)

        if regular or (revealOffgridSectors and offgrid) then
            specs:initialize(x, y, seed)

            if not specs.blocked then
                local revealThisSector = true
                local offgridSectorNote

                if specs.offgrid then
                    -- only offgrid sectors that have a note are revealed
                    -- which offgrid sector has a note is determined based on the captain class
                    local sectorNotes = offgridSectorsToReveal[specs.generationTemplate.path]
                    if sectorNotes then
                        offgridSectorNote = randomEntry(sectorNotes)
                    else
                        revealThisSector = false
                    end
                end

                if revealThisSector then
                    local view = faction:getKnownSector(x, y) or SectorView()

                    if not view.visited and not view.hasContent and not string.match(view.note.text, "${sectorNote}") then
                        specs:fillSectorView(view, gatesMap, true)

                        if view.note.empty then
                            local text = ""
                            local arguments = {}
                            if offgridSectorNote then
                                text = "${sectorNote}"
                                arguments.sectorNote = offgridSectorNote
                            end

                            if self.config.addCaptainsNote then
                                if text ~= "" then text = text .. "\n" end

                                text = text .. captainNoteTemplate
                                arguments.captainNote = captainNote
                                arguments.captainName = captain.name
                            end

                            view.note = NamedFormat(text, arguments)

                            -- make sure that no new icons are created
                            if view.tagIconPath == "" then view.tagIconPath = "data/textures/icons/nothing.png" end
                        end

                        table.insert(sectorsToReveal, view)
                    end
                end
            end
        end
    end

    shuffle(sectorsToReveal)

    local explored = "Explored: "
    local numSectorsToReveal = math.floor(#sectorsToReveal * ratio)
    for index, view in pairs(sectorsToReveal) do
        if index > numSectorsToReveal then break end
        faction:addKnownSector(view)
        explored = explored .. string.format("[%s, %s], ", view:getCoordinates())
    end
    print(explored)
end
