
namespace DataLayer.Model.Repository
{
    public partial class UnitOfWork
    {

        private GenericRepository<JumboSaleRollRDetail> _jumbosalerollrdetailsRepository;
        public GenericRepository<JumboSaleRollRDetail> JumboSaleRollRDetailsRepository
        {
			get { return _jumbosalerollrdetailsRepository ?? (_jumbosalerollrdetailsRepository = new GenericRepository<JumboSaleRollRDetail>(_context)); }
        }
 
    }
}

