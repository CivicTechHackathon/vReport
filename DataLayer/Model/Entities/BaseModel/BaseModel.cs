using System;


namespace DataLayer.Model.Entities.BaseModel
{
    public class BaseModel<TIdType>
    {
        public TIdType Id { get; set; }
        public string CreatedBy { get; set; }
        public DateTime? CreatedDate { get; set; }
        public string UpdatedBy { get; set; }
        public DateTime? UpdatedDate { get; set; }
    }
}
