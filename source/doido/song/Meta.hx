package doido.song;

typedef Meta =
{
    var ?player1:String;
    var ?player2:String;
    var ?gf:String;
    var ?stage:String;
    var ?difficulties:Array<String>;
}

class MetaUtil
{
    function mergeMetas(a:Meta, b:Meta):Meta {
        var meta:Meta = {};
        meta.player1 = (b.player1 ?? a.player1);
        meta.player2 = (b.player2 ?? a.player2);
        meta.gf = (b.gf ?? a.gf);
        meta.stage = (b.stage ?? a.stage);
        meta.difficulties = (b.difficulties ?? a.difficulties);
        return meta;
    }
}