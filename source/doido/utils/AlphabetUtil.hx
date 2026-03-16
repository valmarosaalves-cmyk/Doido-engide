package doido.utils;

import flixel.util.FlxColor;

typedef ParsedText = {
    var chars:Array<String>;
    var tags:Array<TagData>;
}

typedef TagData = {
    var startIndex:Int;
    var endIndex:Int;
    var type:TagType;
}

enum TagType
{
    BoldTag;
    PlainTag;
    ColorTag(value:FlxColor);
    RainbowTag(speed:Float, uniform:Bool);
    ShakeTag(speed:Float, intensity:Float);
    WaveTag(speed:Float, intensity:Float);
}

class AlphabetUtil
{
    public static function parse(text:String):ParsedText
    {
        var chars:Array<String> = [];
        var tags:Array<TagData> = [];
        var openTags:Array<TagData> = [];

        var i:Int = 0;
        var visibleIndex:Int = 0;

        while (i < text.length)
        {
            var c = text.charAt(i);
            if (c == "<")
            {
                var tagEnd = text.indexOf(">", i);
                if (tagEnd == -1) break;

                var tagContent = text.substring(i + 1, tagEnd).trim();

                if (tagContent.startsWith("/"))
                {
                    if (openTags.length > 0)
                    {
                        var tag = openTags.pop();
                        tag.endIndex = visibleIndex;
                        tags.push(tag);
                    }
                }
                else
                {
                    var newTag = parseTag(tagContent, visibleIndex);

                    if (newTag != null)
                        openTags.push(newTag);
                }

                i = tagEnd + 1;
                continue;
            }

            chars.push(c);
            visibleIndex++;
            i++;
        }

        // close any unclosed tags
        for (tag in openTags)
        {
            tag.endIndex = visibleIndex;
            tags.push(tag);
        }

        return {
            chars: chars,
            tags: tags
        };
    }

    static function parseTag(content:String, index:Int):TagData
    {
        if (content.startsWith("bold") || content.startsWith("plain"))
        {
            return {
                startIndex: index,
                endIndex: -1,
                type: content.startsWith("bold") ? BoldTag : PlainTag
            };
        }

        if (content.startsWith("color"))
        {
            var colorIndex = content.indexOf("#");
            if (colorIndex == -1) colorIndex = content.indexOf("0x");

            if (colorIndex != -1)
            {
                var hex = content.substr(colorIndex, content.length);

                return {
                    startIndex: index,
                    endIndex: -1,
                    type: ColorTag(FlxColor.fromString(hex))
                };
            }
        }

        if (content.startsWith("rainbow"))
        {
            var speed = parseFloatTag(content, "speed", 1);
            var uniform = parseBoolTag(content, "uniform", false);

            return {
                startIndex: index,
                endIndex: -1,
                type: RainbowTag(speed, uniform)
            };
        }

        if (content.startsWith("shake"))
        {
            var speed = parseFloatTag(content, "speed", 1);
            var intensity = parseFloatTag(content, "intensity", 5);

            return {
                startIndex: index,
                endIndex: -1,
                type: ShakeTag(speed, intensity)
            };
        }

        if (content.startsWith("wave"))
        {
            var speed = parseFloatTag(content, "speed", 1);
            var intensity = parseFloatTag(content, "intensity", 5);

            return {
                startIndex: index,
                endIndex: -1,
                type: WaveTag(speed, intensity)
            };
        }

        return null;
    }

    static function parseFloatTag(content:String, name:String, defaultValue:Float):Float
    {
        var idx = content.indexOf(name + "=");

        if (idx == -1)
            return defaultValue;

        var start = idx + name.length + 1;
        var end = content.indexOf(" ", start);

        if (end == -1)
            end = content.length;

        var value = content.substring(start, end);
        var parsed = Std.parseFloat(value);

        return Math.isNaN(parsed) ? defaultValue : parsed;
    }

    static function parseBoolTag(content:String, name:String, defaultValue:Bool):Bool
    {
        var idx = content.indexOf(name + "=");
        if (idx == -1)
            return defaultValue;

        var start = idx + name.length + 1;
        var end = content.indexOf(" ", start);

        if (end == -1)
            end = content.length;

        var value = content.substring(start, end);

        return (value == "true" ? true : value == "false" ? false : defaultValue);
    }
}
