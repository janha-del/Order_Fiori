namespace project1.db;

entity Tasks {

    key ID : UUID;

    OrderID : Integer;

    Title : String(120);

    Description : String(500);

    Status : String(20) default 'Open';

    Priority : String(20) default 'Medium';

    AssignedTo : String(255);

    DueDate : Date;

    CreatedBy : String(255);

    CreatedAt : Timestamp;

    CompletedAt : Timestamp;
}
entity OrderReviews {

    key OrderID : Integer;

    ReviewStatus : String(30) default 'Not Reviewed';

    ReviewReason : String(500);

    MarkedBy : String(255);

    MarkedAt : Timestamp;

    AnalystComment : String(500);

    ReviewedBy : String(255);

    ReviewedAt : Timestamp;

}