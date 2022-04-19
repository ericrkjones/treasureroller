using treasureroller.Services;
namespace treasureroller.Models
{
    public class Treasure {
        // private TreasureService context;
        public int Id { get; set; }
        public int? Quantity { get; set; }
        public string? Name { get; set; }
        public string? Description { get; set; }
        public int? Value { get; set; }
        public bool? IsContainer { get; set; }
        public bool? IsVirtual { get; set; }
    }
}