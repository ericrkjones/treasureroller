using treasureroller.Models;
using treasureroller.Services;
using Microsoft.AspNetCore.Mvc;

namespace treasureroller.Controllers;

[ApiController]
[Route("[controller]")]
public class TreasureController : ControllerBase {
    public TreasureController(){
    }

    [HttpGet]
    public ActionResult<List<Treasure>> Get() => TreasureService.GetAllItems();

    [HttpGet("{id}")]
    public ActionResult<List<Treasure>> Get(int id) => TreasureService.GetTreasures(id, 1, 1);

    [HttpGet("{id}/{n}")]
    public ActionResult<List<Treasure>> Get(int id, int n) => TreasureService.GetTreasures(id, n, 1);
}