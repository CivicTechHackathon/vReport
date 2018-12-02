using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Helpers;
using System.Web.Mvc;
using System.Web.UI;
using Microsoft.Ajax.Utilities;
using WebSite.Models;

namespace WebSite.Controllers
{
    public class HomeController : Controller
    {
        readonly ApplicationDbContext _context = new ApplicationDbContext();
        [HttpGet]
        public ActionResult Index()
        {
            ViewBag.Areas = _context.Events.DistinctBy(m => m.Area).ToList();



            return View();
        }
        [HttpPost]
        public ActionResult Index(Event eventModel)
        {

            ViewBag.Areas = _context.Events.DistinctBy(m => m.Area).ToList();

            ViewBag.Crime = _context.Events.Count(m => m.Area == eventModel.Area && m.Category == "Crime");
            ViewBag.Violence = _context.Events.Count(m => m.Area == eventModel.Area && m.Category == "Violence");
            ViewBag.Traffic = _context.Events.Count(m => m.Area == eventModel.Area && m.Category == "Traffic");
            ViewBag.Litter = _context.Events.Count(m => m.Area == eventModel.Area && m.Category == "Litter");



            ViewBag.EventCategorized = _context.Events.Where(m => m.Area == eventModel.Area)
                .GroupBy(m => m.Category)
                .Select(
                    m => new
                    {
                        Name = m.FirstOrDefault().Category,
                        Count = m.Count()
                    }).ToList().Select(m => new GraphMapper { Name = m.Name, Count = m.Count });

            ViewBag.SubCategorizedReports = _context.Events.Where(m => m.Area == eventModel.Area)
              .GroupBy(m => new { m.Category, m.SubCategory }).Select(
                  m => new
                  {
                      Name = m.FirstOrDefault().Category,
                      SubCategory = m.FirstOrDefault().SubCategory,
                      Count = m.Count()
                  }).ToList().Select(m => new GraphMapper
                  {
                      Name = m.Name,
                      SubCategory = m.SubCategory,
                      Count = m.Count
                  });


            return View(eventModel);
        }

        public ActionResult About()
        {
            ViewBag.Message = "Your application description page.";

            return View();
        }

        public ActionResult Contact()
        {
            ViewBag.Message = "Your contact page.";

            return View();
        }

        public Chart Report(string area)
        {
            var w = Request.QueryString["area"];
            var list = _context.Events.Where(m => m.Area == area).GroupBy(m => m.Category).Select(
                  m => new
                  {
                      Name = m.FirstOrDefault().Category,
                      Count = m.Count()
                  }).ToList().Select(m => new GraphMapper
                  {
                      Name = m.Name,
                      Count = m.Count
                  }).ToList();

            var x = new Chart(width: 600, height: 400)
                .AddTitle("Categorized Reports")
                .AddSeries("Default", chartType: "Pie",
                    xField: "Category", xValue: list.Select(m => m.Name).ToList(),
                    yFields: "Count", yValues: list.Select(m => m.Count).ToList()
                ).Write();

            return x;
        }

        public Chart LineReport(string area)
        {
            var w = Request.QueryString["area"];
            var list = _context.Events.Where(m => m.Area == area).DistinctBy(m => m.Category).Select(m => m.Category).ToList();

            var x = new Chart(width: 600, height: 400)
                .AddTitle("Categorized Reports");
            x.AddLegend("Sub Categories", "Sub Categories");
            foreach (var graphMapper in list)
            {
                var data =
                    _context.Events.Where(m => m.Area == area && m.Category == graphMapper).GroupBy(m => m.SubCategory).Select(
                  m => new
                  {
                      Name = m.FirstOrDefault().Category,
                      Count = m.Count()
                  }).ToList().Select(m => new GraphMapper
                  {
                      Name = m.Name,
                      Count = m.Count
                  }).ToList();
                x.AddSeries(graphMapper, axisLabel: graphMapper,
                    xField: "SubCategory", xValue: data.Select(m => m.Name).ToList(), legend: data.FirstOrDefault().SubCategory,
                    yFields: "Count", yValues: data.Select(m => m.Count).ToList());
            }

            return x.Write();
        }
    }

    public class GraphMapper
    {
        public string Name { get; set; }
        public int Count { get; set; }
        public string SubCategory { get; set; }
    }

    public class TableMapper
    {
        public string Category { get; set; }
        public string Name { get; set; }
        public int Count { get; set; }
    }
}