using DataLayer.Model.Entities.BaseModel;
using System;
using System.Collections.Generic;
using System.Data.Entity.Spatial;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DataLayer.Model.Entities
{
    public class GoverningBody : BaseModel<int>
    {
        public string Name { get; set; }
        public string LogoPath { get; set; }
        public bool Verified { get; set; }
        public DbGeography Area { get; set; }
        public string City { get; set; }
        public string Country { get; set; }
    }
}
