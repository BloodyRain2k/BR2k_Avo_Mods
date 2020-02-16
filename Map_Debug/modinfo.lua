
meta =
{
    -- ID of your mod; Make sure this is unique!
    -- Will be used for identifying the mod in dependency lists
    -- Will be changed to workshop ID (ensuring uniqueness) when you upload the mod to the workshop
    id = "1991229637",

    -- Name of your mod; You may want this to be unique, but it's not absolutely necessary.
    -- This is an additional helper attribute for you to easily identify your mod in the Mods() list
    name = "MapDebug",

    -- Title of your mod that will be displayed to players
    title = "Map Debug",

    -- Description of your mod that will be displayed to players
    description = "Meant for debugging map related mods, allows highlighting sectors and paths on the map. \n\n'Player():invokeFunction(\"map_debug\", \"addSectorSet\", sectors, color, name, size)' will put markers around sectors. \n'Player():invokeFunction(\"map_debug\", \"addPathSet\", sectors, color, name)' will draw a path. \n\nThe format for 'sectors' is a simple ivec2 array like { ivec2(100, 100), ivec2(102, 100), ivec2(102, 102) } for both functions. \nFor 'addPathSet' you can also use a table like { \"(100, 100)\" = ivec2(102, 100) }. \n'color' is just a color like ColorARGB / ColorRGB / ColorHSV. \n'name' is for using more than one set at a time, because calling the function again with the same name (or none) and different sectors just replaces them. \n'size' for 'addSectorSet' affects the size of the marker which is useful if you want to have multiple on a sector without them overdrawing each other. \n\nUse 'Player():invokeFunction(\"map_debug\", \"removeSectorSet\", name)' \nand 'Player():invokeFunction(\"map_debug\", \"removePathSet\", name)' to remove a set. If you created them without giving a name, change / remove them the same way.",

    -- Insert all authors into this list
    authors = {"BloodyRain2k"},

    -- Version of your mod, should be in format 1.0.0 (major.minor.patch) or 1.0 (major.minor)
    -- This will be used to check for unmet dependencies or incompatibilities
    version = "1.0",

    -- If your mod requires dependencies, enter them here. The game will check that all dependencies given here are met.
    -- Possible attributes:
    -- id: The ID of the other mod as stated in its modinfo.lua
    -- min, max, exact: version strings that will determine minimum, maximum or exact version required (exact is only syntactic sugar for min == max)
    -- optional: set to true if this mod is only an optional dependency (will only influence load order, not requirement checks)
    -- incompatible: set to true if your mod is incompatible with the other one
    -- Example:
    -- dependencies = {
    --      {id = "Avorion", min = "0.17", max = "0.21"}, -- we can only work with Avorion between versions 0.17 and 0.21
    --      {id = "SomeModLoader", min = "1.0", max = "2.0"}, -- we require SomeModLoader, and we need its version to be between 1.0 and 2.0
    --      {id = "AnotherMod", max = "2.0"}, -- we require AnotherMod, and we need its version to be 2.0 or lower
    --      {id = "IncompatibleMod", incompatible = true}, -- we're incompatible with IncompatibleMod, regardless of its version
    --      {id = "IncompatibleModB", exact = "2.0", incompatible = true}, -- we're incompatible with IncompatibleModB, but only exactly version 2.0
    --      {id = "OptionalMod", min = "0.2", optional = true}, -- we support OptionalMod optionally, starting at version 0.2
    -- },
    dependencies = {
        { id = "Avorion", min = "0.29", max = "0.31.*" }
    },

    -- Set to true if the mod only has to run on the server. Clients will get notified that the mod is running on the server, but they won't download it to themselves
    serverSideOnly = false,

    -- Set to true if the mod only has to run on the client, such as UI mods
    clientSideOnly = true,

    -- Set to true if the mod changes the savegame in a potentially breaking way, as in it adds scripts or mechanics that get saved into database and no longer work once the mod gets disabled
    -- logically, if a mod is client-side only, it can't alter savegames, but Avorion doesn't check for that at the moment
    saveGameAltering = false,

    -- Contact info for other users to reach you in case they have questions
    contact = "@BloodyRain2k on Discord #Avorion",
}
