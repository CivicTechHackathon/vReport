using DataLayer.Model.Entities.BaseModel;
using System;
using System.Collections.Generic;
using System.Data.Entity.Spatial;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DataLayer.Model.Entities
{
    public class Event : BaseModel<int>
    {
        public int CategoryId { get; set; }
        public int SubCategoryId { get; set; }
        public string Description { get; set; }
        public string Area { get; set; }
        public DbGeography Location { get; set; }

        // Add in future
        // public int upVotes { get; set; }
        // public int downVotes { get; set; }

        public virtual ICollection<Tag> Tags { get; set; }
        public virtual Category Category { get; set; }
        public virtual SubCategory SubCategory { get; set; }
        public virtual ICollection<EventMediaDetails> EventMediaDetails { get; set; }
    }

    public class EventMediaDetails
    {
        public int Id { get; set; }
        public int EventId { get; set; }
        public string MediaType { get; set; }
        public string MediaPath { get; set; }


        public virtual Event Event { get; set; }
    }

    public class EventReportDetails : BaseModel<int>
    {
        public int EventId { get; set; }
        public string Status { get; set; }
        public string Description { get; set; }

        public virtual Event Event { get; set; }
    }
}
