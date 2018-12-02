using System.Data.Entity;
using System.Data.Entity.Migrations.Model;


namespace DataLayer.Model.DbContext
{
    public class DataEntities : System.Data.Entity.DbContext
    {
        public DataEntities()
            : base("DataEntities")
        {
            Configuration.LazyLoadingEnabled = false;
        }

        public DbSet<DataLayer.Model.Entities.Category> Categories { get; set; }
    }
}
