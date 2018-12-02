using DataLayer.Model.Entities.BaseModel;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DataLayer.Model.Entities
{
    public class Category : BaseModel<string>
    {
        //Category types will be static list which will be a mother category.. 
        //It will be setup by us and these wont be visible for user. For exaple. 
        //CategoryType 'violance' may contain murder as well as road accident with lots of bloodsheds. 
        //Its sort of tags. For example an event may be tagged as #crime #violnece #murder
        public string Description { get; set; }

        public ICollection<Event> Events { get; set; }
        public ICollection<SubCategory> SubCategories { get; set; }
    }
    public class SubCategory : BaseModel<string>
    {
        public int CategoryId { get; set; }
        public virtual Category Category { get; set; }
    }

    public class Tag : BaseModel<string>
    {
        public ICollection<Event> Events { get; set; }
    }
}
