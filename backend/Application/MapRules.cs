using System.Text.Json;

namespace Tourism;

public sealed class MapRules(string worldPath, string buildingsPath)
{
    private readonly HashSet<(int X,int Y)> roads = Read(worldPath, "roads");
    private readonly HashSet<(int X,int Y)> water = Read(worldPath, "water");
    private static readonly (int X,int Y)[] directions = [(1,0),(-1,0),(0,1),(0,-1)];

    private static HashSet<(int,int)> Read(string path, string field)
    {
        using var world = JsonDocument.Parse(File.ReadAllText(path));
        return world.RootElement.GetProperty(field).EnumerateArray().Select(p => (p[0].GetInt32(), p[1].GetInt32())).ToHashSet();
    }

    private readonly (int X, int Y) gate = ReadGate(worldPath);
	private readonly Dictionary<string, (int W, int H)> sizes = ReadSizes(buildingsPath);

	private static (int, int) ReadGate(string path)
	{
		using var doc = JsonDocument.Parse(File.ReadAllText(path));
		var cell = doc.RootElement.GetProperty("gate");
		return (cell[0].GetInt32(), cell[1].GetInt32());
	}

	private static Dictionary<string, (int, int)> ReadSizes(string path)
	{
		using var doc = JsonDocument.Parse(File.ReadAllText(path));
		return doc.RootElement.EnumerateArray().ToDictionary(
			b => b.GetProperty("id").GetString()!,
			b => (b.GetProperty("size")[0].GetInt32(), b.GetProperty("size")[1].GetInt32()));
	}
    private IEnumerable<(int X,int Y)> Footprint(string kind, int x, int y)
    {
        var (w,h) = sizes[kind];
        return from dx in Enumerable.Range(0,w) from dy in Enumerable.Range(0,h) select (x+dx,y+dy);
    }

    public void Validate(Asset plot, string kind, int x, int y, List<Facility> facilities)
    {
        if (x < plot.X || y < plot.Y || x >= plot.X + plot.Width || y >= plot.Y + plot.Height)
            throw new RuleException("Vị trí nằm ngoài ranh giới lô.");
        var cells = Footprint(kind,x,y).ToArray();
        if (cells.Any(p => p.X >= plot.X + plot.Width || p.Y >= plot.Y + plot.Height || roads.Contains(p) || water.Contains(p)))
            throw new RuleException("Vượt ranh giới lô hoặc chồng lên đường hay mặt nước.");
        if (facilities.SelectMany(f => Footprint(f.Kind,f.X,f.Y)).Intersect(cells).Any())
            throw new RuleException("Vị trí đã có công trình.");
        var reachable = new HashSet<(int X,int Y)> { gate };
        var queue = new Queue<(int X,int Y)>(reachable);
        while (queue.TryDequeue(out var point))
            foreach (var dir in directions)
            {
                var next = (point.X + dir.X, point.Y + dir.Y);
                if (roads.Contains(next) && reachable.Add(next)) queue.Enqueue(next);
            }
        if (!cells.Any(p => directions.Any(d => reachable.Contains((p.X + d.X,p.Y + d.Y)))))
            throw new RuleException("Công trình phải có lối tiếp cận kết nối với cổng.");
    }
}

