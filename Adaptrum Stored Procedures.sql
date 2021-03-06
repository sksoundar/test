/****** Object:  StoredProcedure [dbo].[USP_GetAllInventoryitems]    Script Date: 07-05-2019 13:44:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_GetAllInventoryitems]  
AS  
BEGIN  
    SET NOCOUNT ON;  
 SELECT  ISNULL(InventoryItemId,0)InventoryItemId,ISNULL(PartNumber,'')PartNumber,ISNULL(Price,0)Price,ISNULL(Stock,0)Stock,  
 ISNULL(HasFile,0)HasFile,ISNULL(ItemName,'')ItemName,ISNULL(org.Name,'') AS ManufacturerName FROM inventoryitems i WITH (NOLOCK)      
 INNER JOIN InventoryItemTypes it on it.InventoryItemTypeId=i.InventoryItemTypeId      
 INNER JOIN Organizations org on org.OrganizationId=i.OrganizationId WHERE i.IsActive=1  
END
GO
/****** Object:  StoredProcedure [dbo].[USP_GetAllOrganization]    Script Date: 07-05-2019 13:44:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_GetAllOrganization]  
AS   
BEGIN  
SET NOCOUNT ON;     
SELECT ISNULL(ORG.OrganizationId,0) AS OrganizationId,ISNULL(ORG.Name,'') AS OrganizationName,  
ISNULL(ORGC.OrganizationCategoryName,'') AS OrganizationCategory,ISNULL(ORG1.Name,'') AS ParentOrganizationName   
FROM Organizations ORG WITH(NOLOCK)  
INNER JOIN OrganizationCategories ORGC WITH(NOLOCK) ON ORGC.OrganizationCategoryId=ORG.OrganizationCategoryId  
LEFT JOIN Organizations ORG1 on ORG1.ParentOrganizationId=ORG.OrganizationId ORDER BY OrganizationId DESC 
END  
GO
/****** Object:  StoredProcedure [dbo].[USP_GetAllRMA]    Script Date: 07-05-2019 13:44:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[USP_GetAllRMA]
AS  
BEGIN
SET NOCOUNT ON;   
SELECT ISNULL(TicketNumber,'')TicketNumber,R.CreatedDate, ISNULL(R.Email,'') Email,ISNULL(R.CreatedBy,'') CreatedBy,
ISNULL(Phone,'')Phone,ISNULL(ORG.Name,'') AS OrganizationName,ISNULL(U.UserName,'') AssignedByUserName,
ISNULL(RSTA.RmaStatus,'')RmaStatus,ISNULL(R.RMAStatusId,0) RMAStatusId FROM RMA R  
LEFT JOIN Organizations ORG ON ORG.OrganizationId=R.OrganizationId  
LEFT JOIN Users U on U.UserId= R.AssignedByuser AND AssignedByuser IS NOT NULL  
LEFT JOIN RMAStatus RSTA on RSTA.RMAStatusId= R.RMAStatusId ORDER BY CreatedDate desc
END
GO
/****** Object:  StoredProcedure [dbo].[USP_GetCustomerPricing]    Script Date: 07-05-2019 13:44:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:     Anitha
-- Create Date: April 23rd, 2019
-- Description: Retrieve Customer Pricing and Disocunts by UserId
-- EXEC [USP_GetCustomerPricing] '54cd3a88-465c-4be9-a45d-184fe97c0fcc','CP'  
--EXEC [USP_GetCustomerPricing] '54cd3a88-465c-4be9-a45d-184fe97c0fcc',1  
-- =============================================
CREATE PROCEDURE [dbo].[USP_GetCustomerPricing]
(
   @userId VARCHAR(200)= '',  
   @returnType VARCHAR(200)= '' 
)
AS
BEGIN
   SET NOCOUNT ON;    
 DECLARE @roleName VARCHAR(200)    
 DECLARE @roleId VARCHAR(200)    
    
 SELECT TOP 1  @roleId = RoleId FROM USERROLES WITH(NOLOCK) WHERE USERID = @userId
 SELECT TOP 1 @roleName = ROLENAME FROM ROLES WITH(NOLOCK) WHERE  ROLEID= @roleId    
    
 PRINT @roleId + ' - RoleID'    
 PRINT @roleName + ' - RoleName'  

 DECLARE @IsHaveFullRightsForInventoryPricing BIT 
 DECLARE @IsHaveFullRightsForInventoryPricingDiscount BIT        
      
  IF EXISTS (SELECT * FROM roleactions  WITH (NOLOCK) WHERE roleid=@roleId AND actionid IN ( SELECT actionid FROM actions     
   WITH (NOLOCK) WHERE actionname='AirbandCustomerPricing'))    
  BEGIN     
   SET @IsHaveFullRightsForInventoryPricing =1    
  END    
  ELSE SET  @IsHaveFullRightsForInventoryPricing =0   
        
      
  IF EXISTS (SELECT * FROM roleactions  WITH (NOLOCK) WHERE roleid=@roleId AND actionid IN ( SELECT actionid FROM actions     
   WITH (NOLOCK) WHERE actionname='AirbandCustomerPricingDiscount'))    
  BEGIN     
   SET @IsHaveFullRightsForInventoryPricingDiscount =1    
  END    
  ELSE SET  @IsHaveFullRightsForInventoryPricingDiscount =0   
  
   IF @IsHaveFullRightsForInventoryPricing = 1     
	BEGIN    
       IF(@returnType='CP')  
		BEGIN 
			SELECT  IsNULL(cp.CustomerPricingId,0) AS CustomerPricingId, inv.InventoryItemId, inv.ItemName As InventoryItemName, inv.PartNumber, 
			 IsNULL( cp.Price, inv.Price) As Price, 4 AS CustomerTypeId
			 FROM Inventoryitems inv 
			 LEFT JOIN CustomerPricing cp ON inv.InventoryItemId = cp.InventoryItemId
			 WHERE inv.IsActive = 1
		END
    END     

	print @returnType 
	print @IsHaveFullRightsForInventoryPricingDiscount
	IF @IsHaveFullRightsForInventoryPricingDiscount = 1     
	BEGIN    
       IF(@returnType <> 'CP')  
		BEGIN 
		  SELECT  IsNULL(cpd.CustomerPricingDiscountId,0) AS CustomerPricingDiscountId, inv.InventoryItemId,
		 inv.ItemName As InventoryItemName, inv.PartNumber,ISNULL( cp.CustomerPricingId,0) as CustomerPricingId,
		 IsNULL( cp.Price, 0.00) As Price,  IsNULL(cpd.Discount, 0.00) As Discount,
		 CONVERT(varchar, CAST(IsNULL(cp.Price, 0.00) AS money) - CAST(IsNULL(cp.Price * (cpd.Discount / 100), 0.00) AS money), 1) As DiscountedPrice,
		 IsNULL( cpd.PricingCategoryId, 0) As PricingCategoryId
		 FROM Inventoryitems inv
		 LEFT JOIN CustomerPricing cp ON inv.InventoryItemId = cp.InventoryItemId
		 LEFT JOIN CustomerPricingDiscounts cpd ON cpd.CustomerPricingId = cp.CustomerPricingId
		 AND cpd.PricingCategoryId = @returnType WHERE inv.IsActive = 1
		 END
    END  
END

GO
/****** Object:  StoredProcedure [dbo].[USP_GetDeviceList]    Script Date: 07-05-2019 13:44:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================      
-- Author:      ANITHA C      
-- Create Date: 17 APR 2019      
-- Description: To retirve the User Dashboard count      
-- EXEC USP_GetDeviceList '54cd3a88-465c-4be9-a45d-184fe97c0fcc',0,0      
-- EXEC USP_GetDeviceList '54cd3a88-465c-4be9-a45d-184fe97c0fcc',5,1      
-- EXEC USP_GetDeviceList '54cd3a88-465c-4be9-a45d-184fe97c0fcc',0,0      
-- @returnType if 0 is DeviceList, if 1 is DeviceGroupList     
-- =============================================      
CREATE PROCEDURE [dbo].[USP_GetDeviceList]      
(      
   @userId VARCHAR(200), @deviceGroupId INT, @returnType INT      
)      
AS      
BEGIN      
SET NOCOUNT ON;         
      
DECLARE @onlyCMCreated BIT = 1;      
DECLARE @roleId VARCHAR(200) =  (SELECT Roleid FROM userroles WHERE userid = @userId)      
DECLARE @roleName VARCHAR(200) = (SELECT Rolename FROM roles WHERE roleid = @roleId)      
DECLARE @loggedInUserOrganizationID INT       
      
PRINT  @roleId      
PRINT @roleName      
      
IF @roleName = 'SuperAdmin' OR @roleName = 'AdaptrumAdmin'       
BEGIN      
 SET @onlyCMCreated = 0      
END      
      
PRINT @onlyCMCreated      
      
SET @loggedInUserOrganizationID =  (SELECT top 1 OrganizationId FROM Organizationusers WHERE userid = @userId)      
PRINT @loggedInUserOrganizationID      
    
IF(@returnType=1)      
BEGIN    
IF @onlyCMCreated = 1      
 BEGIN      
  SELECT ISNULL(d.DeviceGroupId,0)DeviceGroupId, ISNULL(d.DeviceGroupName,'')DeviceGroupName,ISNULL(d.OrganizationId,0)OrganizationId,     
  ISNULL(o.Name,'') AS ManufacturerName,ISNULL(d.Description,'')Description FROM devicegroups d      
  INNER JOIN Organizations o ON o.OrganizationId = d.OrganizationId      
  WHERE d.IsActive = 1 AND d.OrganizationId = @loggedInUserOrganizationID     
  
 END      
ELSE       
 BEGIN      
  SELECT ISNULL(d.DeviceGroupId,0)DeviceGroupId, ISNULL(d.DeviceGroupName,'')DeviceGroupName,ISNULL(d.OrganizationId,0)OrganizationId,     
  ISNULL(o.Name,'') AS ManufacturerName,ISNULL(d.Description,'')Description FROM devicegroups d      
  INNER JOIN Organizations o ON o.OrganizationId = d.OrganizationId      
  WHERE d.IsActive = 1    
 END      
END      
DECLARE @viewAllDevices INT =0      
DECLARE @viewDevicesAddedByAllUserInOrganization INT = 0      
      
      
SET @viewAllDevices = (select top 1 RoleActionId from roleactions WHERE RoleId = @roleId AND      
 actionId in (select top 1 actionId from actions WHERE ActionName = 'ViewAllDevices'))      
      
 SET @viewDevicesAddedByAllUserInOrganization = (select TOP 1 RoleActionId from roleactions WHERE RoleId = @roleId AND      
 actionId in (select top 1 actionId from actions WHERE ActionName = 'ViewDevicesAddedByAllUserInOrganization'))      
      
 --SELECT @viewAllDevices As ViewAllDevices, @deviceGroupId, @viewDevicesAddedByAllUserInOrganization,@roleName      
 IF(@returnType=0)       
 BEGIN    
  IF @viewAllDevices > 0       
 BEGIN      
   SELECT ISNULL(dg.DeviceGroupId,0)DeviceGroupId,  
 ISNULL(dg.DeviceGroupName,'')AS DeviceGroupName FROM DeviceGroups dg  
 WHERE  dg.IsActive = 1  
 IF @deviceGroupId = 0      
  BEGIN      
 SELECT ISNULL(d.DeviceId,0)DeviceId,ISNULL(d.DeviceGroupId,0)DeviceGroupId,ISNULL(d.SerialNumber,'') AS SerialNumber,    
 ISNULL(dg.DeviceGroupName,'') AS DeviceGroupName,       
 ISNULL(inv.ItemName,'') AS InventoryItemName,ISNULL(invT.InventoryItemTypeName,'') AS InventoryItemType,      
 ISNULL(o.Name,'') AS ManufacturerName      
 FROM Devices d       
 LEFT JOIN DeviceGroups dg ON d.DeviceGroupid = dg.DeviceGroupid      
 LEFT JOIN InventoryItems inv ON inv.InventoryitemId = d.InventoryitemId      
 LEFT JOIN InventoryItemTypes invT ON invT.InventoryItemTypeId = inv.InventoryItemTypeId      
 LEFT JOIN Organizations o ON o.OrganizationId = d.OrganizationId      
 WHERE  dg.IsActive = 1 AND d.shipmentid IS NULL        
 ORDER BY d.CreatedDate DESC      
  END      
 ELSE IF @deviceGroupId > 0      
  BEGIN      
 SELECT ISNULL(d.DeviceId,0)DeviceId,ISNULL(d.DeviceGroupId,0)DeviceGroupId,ISNULL(d.SerialNumber,'') AS SerialNumber,    
 ISNULL(dg.DeviceGroupName,'') AS DeviceGroupName,       
 ISNULL(inv.ItemName,'') AS InventoryItemName,ISNULL(invT.InventoryItemTypeName,'') AS InventoryItemType,      
 ISNULL(o.Name,'') AS ManufacturerName     
 FROM Devices d       
 LEFT JOIN DeviceGroups dg ON d.DeviceGroupid = dg.DeviceGroupid      
 LEFT JOIN InventoryItems inv ON inv.InventoryitemId = d.InventoryitemId      
 LEFT JOIN InventoryItemTypes invT ON invT.InventoryItemTypeId = inv.InventoryItemTypeId      
 LEFT JOIN Organizations o ON o.OrganizationId = d.OrganizationId      
 WHERE  dg.IsActive = 1 AND d.shipmentid IS NULL  AND d.DeviceGroupid = @deviceGroupId      
 ORDER BY d.CreatedDate DESC      
  END      
 END       
  ELSE IF  @viewDevicesAddedByAllUserInOrganization > 0        
 BEGIN     
  SELECT ISNULL(dg.DeviceGroupId,0)DeviceGroupId,  
 ISNULL(dg.DeviceGroupName,'')AS DeviceGroupName FROM DeviceGroups dg  
 LEFT JOIN Organizations o ON o.OrganizationId = dg.OrganizationId      
 WHERE  dg.IsActive = 1 AND dg.OrganizationId = @loggedInUserOrganizationID     
     
 IF @deviceGroupId = 0      
  BEGIN      
 SELECT ISNULL(d.DeviceId,0)DeviceId,ISNULL(d.DeviceGroupId,0)DeviceGroupId,ISNULL(d.SerialNumber,'') AS SerialNumber,    
 ISNULL(dg.DeviceGroupName,'') AS DeviceGroupName,       
 ISNULL(inv.ItemName,'') AS InventoryItemName,ISNULL(invT.InventoryItemTypeName,'') AS InventoryItemType,      
 ISNULL(o.Name,'') AS ManufacturerName     
 FROM Devices d       
 LEFT JOIN DeviceGroups dg ON d.DeviceGroupid = dg.DeviceGroupid      
 LEFT JOIN InventoryItems inv ON inv.InventoryitemId = d.InventoryitemId      
 LEFT JOIN InventoryItemTypes invT ON invT.InventoryItemTypeId = inv.InventoryItemTypeId      
 LEFT JOIN Organizations o ON o.OrganizationId = d.OrganizationId      
 WHERE  dg.IsActive = 1 AND d.shipmentid IS NULL AND d.OrganizationId = @loggedInUserOrganizationID      
 ORDER BY d.CreatedDate DESC      
 END       
 ELSE IF  @deviceGroupId > 0      
  BEGIN        
 SELECT ISNULL(d.DeviceId,0)DeviceId,ISNULL(d.DeviceGroupId,0)DeviceGroupId,ISNULL(d.SerialNumber,'') AS SerialNumber,    
 ISNULL(dg.DeviceGroupName,'') AS DeviceGroupName,       
 ISNULL(inv.ItemName,'') AS InventoryItemName,ISNULL(invT.InventoryItemTypeName,'') AS InventoryItemType,      
 ISNULL(o.Name,'') AS ManufacturerName     
 FROM Devices d       
 LEFT JOIN DeviceGroups dg ON d.DeviceGroupid = dg.DeviceGroupid      
 LEFT JOIN InventoryItems inv ON inv.InventoryitemId = d.InventoryitemId      
 LEFT JOIN InventoryItemTypes invT ON invT.InventoryItemTypeId = inv.InventoryItemTypeId      
 LEFT JOIN Organizations o ON o.OrganizationId = d.OrganizationId       
 WHERE  dg.IsActive = 1 AND d.shipmentid IS NULL AND d.OrganizationId = @loggedInUserOrganizationID      
 AND d.DeviceGroupid = @deviceGroupId      
 ORDER BY d.CreatedDate DESC      
 END       
  ELSE       
 BEGIN       
  IF  @deviceGroupId > 0      
   BEGIN       
    SELECT ISNULL(d.DeviceId,0)DeviceId,ISNULL(d.DeviceGroupId,0)DeviceGroupId,ISNULL(d.SerialNumber,'') AS SerialNumber,    
    ISNULL(dg.DeviceGroupName,'') AS DeviceGroupName,       
    ISNULL(inv.ItemName,'') AS InventoryItemName,ISNULL(invT.InventoryItemTypeName,'') AS InventoryItemType,      
    ISNULL(o.Name,'') AS ManufacturerName       
    FROM Devices d       
    LEFT JOIN DeviceGroups dg ON d.DeviceGroupid = dg.DeviceGroupid      
    LEFT JOIN InventoryItems inv ON inv.InventoryitemId = d.InventoryitemId      
    LEFT JOIN InventoryItemTypes invT ON invT.InventoryItemTypeId = inv.InventoryItemTypeId      
    LEFT JOIN Organizations o ON o.OrganizationId = d.OrganizationId       
    WHERE  dg.IsActive = 1 AND d.shipmentid IS NULL AND d.CreatedBy = @userId AND d.DeviceGroupid = @deviceGroupId      
    ORDER BY d.CreatedDate DESC      
   END      
  ELSE IF @deviceGroupId = 0      
   BEGIN       
    SELECT ISNULL(d.DeviceId,0)DeviceId,ISNULL(d.DeviceGroupId,0)DeviceGroupId,ISNULL(d.SerialNumber,'') AS SerialNumber,    
    ISNULL(dg.DeviceGroupName,'') AS DeviceGroupName,       
    ISNULL(inv.ItemName,'') AS InventoryItemName,ISNULL(invT.InventoryItemTypeName,'') AS InventoryItemType,      
    ISNULL(o.Name,'') AS ManufacturerName     
    FROM Devices d       
    LEFT JOIN DeviceGroups dg ON d.DeviceGroupid = dg.DeviceGroupid      
    LEFT JOIN InventoryItems inv ON inv.InventoryitemId = d.InventoryitemId      
    LEFT JOIN InventoryItemTypes invT ON invT.InventoryItemTypeId = inv.InventoryItemTypeId      
    LEFT JOIN Organizations o ON o.OrganizationId = d.OrganizationId       
    WHERE  dg.IsActive = 1 AND d.shipmentid IS NULL AND d.CreatedBy = @userId       
    ORDER BY d.CreatedDate DESC      
   END      
  END    
 END      
END      
END      
      
       
      
    
    
GO
/****** Object:  StoredProcedure [dbo].[USP_GetListOfInventoryItemsBasedonUserOrganization]    Script Date: 07-05-2019 13:44:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
-- =============================================    
-- Author:  PONMANI SASIKUMAR    
-- Create date: 24 APR 2019    
-- Description: To retirve inventory items for quotation 
-- EXEC [USP_GetListOfInventoryItemsBasedonUserOrganization] 4
-- EXEC [USP_GetListOfInventoryItemsBasedonUserOrganization] 1
-- =============================================    
CREATE PROCEDURE [dbo].[USP_GetListOfInventoryItemsBasedonUserOrganization]    
 @organizationId INT= 0     
AS
BEGIN

SET NOCOUNT ON;  
	 DECLARE @CustomerCategoryId INT
	 DECLARE @PricingCategoryId INT
  
 
 SELECT TOP 1 @CustomerCategoryId = CustomerTypeId, @PricingCategoryId =PricingCategoryId FROM Organizations where  OrganizationId=@organizationId
 
 IF @OrganizationId<>0 AND @CustomerCategoryId=4
 BEGIN
 SELECT INV.InventoryItemID, INV.ItemName,
  CAST(CASE WHEN CP.Price IS NULL  THEN  ROUND(INV.Price,2) 
 WHEN CP.Price IS NOT NULL AND CPD.Discount  IS NOT NULL  THEN  ROUND( CP.Price -( CP.Price *(CPD.Discount/100) ),2)
 ELSE   ROUND(CP.Price,2) END as DECIMAL(18,2)) as Price ,
INV.Stock, INV.PartNumber,
   CAST (1 as BIT) as IsAirbandCustomer 
 FROM  INVENTORYITEMS INV LEFT JOIN  [CustomerPricing] CP ON INV.Inventoryitemid = CP.InventoryItemID 
 LEFT JOIN CustomerPricingDiscounts CPD ON CPD.CustomerPricingId =CP.CustomerPricingId  AND PricingCAtegoryid=@PricingCategoryId
 WHERE INV.isactive=1
END
 ELSE
 BEGIN
 SELECT InventoryItemID,INV.ItemName,CAST(INV.Price as DECIMAL(18,2)) as Price,
  INV.Stock, INV.PartNumber ,
   CAST (0 as BIT) as IsAirbandCustomer  FROM  INVENTORYITEMS INV   WHERE INV.isactive=1
  END
END
GO
/****** Object:  StoredProcedure [dbo].[USP_GetOrders]    Script Date: 07-05-2019 13:44:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================      
-- Author:  PONMANI SASIKUMAR      
-- Create date: 17 APR 2019      
-- Description: To retirve the Orders      
-- EXEC [USP_GetOrders] 'a6699764-327a-470b-9990-81a842c67576'      
-- EXEC [USP_GetOrders] 'a50621f5-7ff4-43c2-b429-a3860f8acd0a'     
-- =============================================      
CREATE PROCEDURE [dbo].[USP_GetOrders]       
 @userId VARCHAR(200)= ''      
AS      
BEGIN     
 SET NOCOUNT ON;       
 DECLARE @roleName VARCHAR(200)      
 DECLARE @roleId VARCHAR(200)      
      
 SELECT TOP 1  @roleId = RoleId FROM USERROLES  WITH (NOLOCK) WHERE USERID = @userId      
      
 SELECT TOP 1 @roleName = ROLENAME FROM ROLES  WITH (NOLOCK) WHERE  ROLEID= @roleId      
      
 PRINT @roleId + ' - RoleID'      
 PRINT @roleName + ' - RoleName'      
      
       
 DECLARE @IsHaveFullRightsForOrders BIT         
        
  IF EXISTS (SELECT * FROM roleactions  WITH (NOLOCK) WHERE roleid=@roleId AND actionid IN ( SELECT actionid FROM actions       
   WITH (NOLOCK) WHERE actionname='OrderListViewAll'))      
  BEGIN       
   SET @IsHaveFullRightsForOrders =1      
  END      
  ELSE SET  @IsHaveFullRightsForOrders =0      
  
  
SELECT  A.PurchaseOrderId, MIN(IsFulFilledQuantity)IsFulFilledQuantity INTO #tempQuantityFulfilled from ( SELECT  A.PurchaseOrderId,B.InventoryitemID,SUM(B.Quantity) as OrderQuanity, MAX(D.Quantity ) as POQuanity, CASE WHEN  SUM(B.Quantity)=MAX(D.Quantity
) THEN 1 ELSE 0 END as IsFulFilledQuantity FROM ORDERS A INNER JOIN ORDERITEMS B ON A.ORDERID=B.ORDERID LEFT JOIN PURCHASEORDERS C ON A.PurchaseOrderId= C.PurchaseorderID 
LEFT JOIN PURCHASEORDERITEMS D ON A.PurchaseorderID= D.PurchaseorderID AND B.InventoryitemID = D.InventoryitemID  WHERE ORDERMODESID=1 GROUP BY  A.PurchaseOrderId,B.InventoryitemID) A GROUP BY PurchaseOrderId  
      
       
 PRINT CASE WHEN @IsHaveFullRightsForOrders=1 THEN 'YES' ELSE 'No' END + ' - Have Rights to view all orders'      
      
 IF @IsHaveFullRightsForOrders =1       
 BEGIN    
  SELECT ISNULL(OrderId,0)OrderId,ISNULL(OrderNumber,'')OrderNumber,ISNULL(OS.OrderStatusId,0)OrderStatusId,  
  ISNULL(OM.OrderModesId,0)OrderModesId,ORD.CreatedDate,ISNULL(ORD.ParentOrderID,0) AS ParentOrderID,    
      ORD.CreatedDate AS  PlacedDate,ISNULL(PurchaseOrder,'')PurchaseOrder,ISNULL(CustomerName,'')CustomerName,  
   ISNULL(Email,'') AS PlacedBy,ISNULL(OrderModesName,'')OrderModesName,ISNULL(OrderStatusName,'') AS OrderStatus,
   ISNULL(QF.IsFulFilledQuantity,0)IsFulFilledQuantity,  
  CASE WHEN ORD.ParentOrderID IS NOT NULL THEN 1 ELSE 0 END  'IsHaveBackOrder',     
     (SELECT TOP 1 ISNULL(Email,'') FROM orderitems A  WITH (NOLOCK)   
  INNER JOIN USERS U ON A.CMFulfilmentId = U.UserId WHERE orderid = ORD.orderid) AS AssignedToCM,    
  ISNULL(O.Name,'') AS OrganizationName ,ISNULL(ORD.HasFile,0)HasFile,ISNULL(ORD.PurchaseOrderId,0)PurchaseOrderId FROM ORDERS ORD  WITH (NOLOCK)   
  INNER JOIN USERS USR ON ORD.CreatedBy = USR.UserID      
  INNER JOIN ORDERMODES OM  WITH (NOLOCK) ON OM. OrderModesId=ORD.OrderModesId       
  INNER JOIN ORDERSTATUS OS WITH (NOLOCK) ON  OS.OrderStatusId = ORD.OrderStatusId    
  INNER JOIN organizations O WITH (NOLOCK) ON  O.OrganizationId = ORD.OrganizationId    
  LEFT JOIN #tempQuantityFulfilled QF WITH (NOLOCK) ON  QF.PurchaseOrderId = ORD.PurchaseOrderId ORDER BY  OrderId DESC  
  END      
    ELSE       
 BEGIN      
  SELECT ISNULL(OrderId,0)OrderId,ISNULL(OrderNumber,'')OrderNumber,ISNULL(OS.OrderStatusId,0)OrderStatusId,  
   ISNULL(OM.OrderModesId,0)OrderModesId,ORD.CreatedDate,ISNULL(ORD.ParentOrderID,0) AS ParentOrderID,    
     ORD.CreatedDate AS  PlacedDate,ISNULL(PurchaseOrder,'')PurchaseOrder,ISNULL(CustomerName,'')CustomerName,  
   ISNULL(Email,'') AS PlacedBy,ISNULL(OrderModesName,'')OrderModesName,ISNULL(OrderStatusName,'') AS OrderStatus,
   ISNULL(QF.IsFulFilledQuantity,0)IsFulFilledQuantity,   
    CASE WHEN ORD.ParentOrderID IS NOT NULL THEN 1 ELSE 0 END  'IsHaveBackOrder',          
     (SELECT TOP 1 ISNULL(Email,'') from orderitems A  WITH (NOLOCK)   
  INNER JOIN USERS U ON A.CMFulfilmentId = U.UserId where orderid = ORD.orderid)    
     AS AssignedToCM,ISNULL(O.Name,'') AS OrganizationName ,ORD.HasFile,ISNULL(ORD.PurchaseOrderId,0)PurchaseOrderId FROM ORDERS ORD  WITH (NOLOCK)  
  INNER JOIN USERS USR ON ORD.CreatedBy = USR.UserID      
     INNER JOIN ORDERMODES OM  WITH (NOLOCK) ON OM. OrderModesId=ORD.OrderModesId       
     INNER JOIN ORDERSTATUS OS  WITH (NOLOCK) ON OS.OrderStatusId = ORD.OrderStatusId    
     INNER JOIN organizations O WITH (NOLOCK) ON  O.OrganizationId = ORD.OrganizationId  
     LEFT JOIN #tempQuantityFulfilled QF WITH (NOLOCK) ON  QF.PurchaseOrderId = ORD.PurchaseOrderId    
      WHERE ORD.CreatedBy = @userId  ORDER BY  OrderId DESC       
 END      
      DROP TABLE #tempQuantityFulfilled       
  
END      
  
GO
/****** Object:  StoredProcedure [dbo].[USP_GetOrdersForShipmentAndShippedOrders]    Script Date: 07-05-2019 13:44:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

  
-- =============================================      
-- Author:  PONMANI SASIKUMAR      
-- Create date: 17 APR 2019      
-- Description: To retirve the Orders Pending for shipment and Shipped orders       
-- EXEC [USP_GetOrdersForShipmentAndShippedOrders] '594ae141-2835-495c-9392-8784095788db',0      
--EXEC [USP_GetOrdersForShipmentAndShippedOrders] '594ae141-2835-495c-9392-8784095788db',1    
-- =============================================      
CREATE PROCEDURE [dbo].[USP_GetOrdersForShipmentAndShippedOrders]       
 @userId VARCHAR(200)= '',    
 @returnType VARCHAR(200)= ''       
AS      
BEGIN      
 SET NOCOUNT ON;      
 DECLARE @roleName VARCHAR(200)      
 DECLARE @roleId VARCHAR(200)      
      
 SELECT TOP 1  @roleId = RoleId FROM USERROLES WITH(NOLOCK) WHERE USERID = @userId      
      
 SELECT TOP 1 @roleName = ROLENAME FROM ROLES WITH(NOLOCK) WHERE  ROLEID= @roleId      
      
 PRINT @roleId + ' - RoleID'      
 PRINT @roleName + ' - RoleName'      
      
       
 DECLARE @IsAllShipments BIT           
        
  IF @roleName = 'CMFulfilment'      
  BEGIN       
   SET @IsAllShipments =0      
  END      
  ELSE SET @IsAllShipments =1      
          
 PRINT CASE WHEN @IsAllShipments=0 THEN 'YES' ELSE 'No' END + ' - Only CM Created/Assigned'      
      
 IF @IsAllShipments =1  AND (@roleName = 'AdaptrumAdmin' OR @roleName='SuperAdmin')      
 BEGIN      
    IF(@returnType='0')    
 BEGIN    
   SELECT ISNULL(OrderID,0)OrderID,ISNULL(OrderNumber,'')OrderNumber,ISNULL(AB.FormattedAddress,'') AS FormattedAddress,  
   ISNULL(ord.OrderStatusID,0) AS OrderStatusId,'Ready to Ship' AS OrderStatus,CreatedDate AS PlacedDate,      
    (SELECT TOP 1 ISNULL(Email,'') FROM orderitems A WITH(NOLOCK)INNER JOIN USERS U WITH(NOLOCK)ON A.CMFulfilmentId = U.UserId WHERE orderid = ORD.orderid) AS  AssignedToCM      
    FROM ORDERS ORD      
   INNER JOIN ADDRESSBOOK AB WITH(NOLOCK)ON ORD.BillToAddressId =AB.AddressId  WHERE ORD.OrderStatusID= 3  ORDER BY OrderID DESC    
  END    
  ELSE    
    SELECT ISNULL(s.ShipmentId,0)ShipmentId,ISNULL(s.ShipmentNumber,'')ShipmentNumber,ISNULL(s.TrackingNumber,'')TrackingNumber,ISNULL(s.CreatedBy,'')CreatedBy,   
  s.ShippingDate,ISNULL(os.OrderStatusName,'') AS Status,ISNULL(org.Name,'') AS OrganizationName,   
 ISNULL(u.Email,'') AS AssignedToCM,STUFF((Select ',' + CAST (SerialNumber AS VARCHAR(5))      
    FROM Devices D WITH(NOLOCK) WHERE D.ShipmentId=s.ShipmentId AND  SerialNumber IS NOT NULL AND SerialNumber<>'' FOR XML PATH('')),1,1,'') AS ShippedDevicesSerialNos      
 FROM Shipments s WITH(NOLOCK) LEFT JOIN Orderstatus os ON os.OrderStatusId = s.ShipmentStatus      
    LEFT JOIN Orders ord WITH(NOLOCK) ON  ord.OrderId = s.OrderId LEFT JOIN Organizations org WITH(NOLOCK) ON org.OrganizationId = ord.OrganizationId      
    LEFT JOIN Users u WITH(NOLOCK) ON u.UserId = s.CreatedBy WHERE ord.OrderStatusID=5  ORDER BY ShipmentId DESC    
      
  END      
    ELSE       
 BEGIN      
      IF(@returnType='0')    
 BEGIN    
   SELECT DISTINCT ISNULL(ORD.OrderID,0)OrderID,ISNULL(OrderNumber,'')OrderNumber,ISNULL(AB.FormattedAddress,'')FormattedAddress,ISNULL(ord.OrderStatusID,0) AS OrderStatusId,  
   'Ready to Ship' AS OrderStatus,CreatedDate as PlacedDate,        
    (SELECT TOP 1 Email from orderitems A WITH(NOLOCK) INNER JOIN USERS U WITH(NOLOCK) ON A.CMFulfilmentId = U.UserId where orderid = ORD.orderid) as  AssignedToCM          
    FROM ORDERS ORD  WITH(NOLOCK)    
   INNER JOIN ADDRESSBOOK AB WITH(NOLOCK) ON ORD.BillToAddressId =AB.AddressId      
   INNER JOIN ORDERITEMS OI WITH(NOLOCK) ON OI.OrderId=ORD.OrderID   WHERE ORD.OrderStatusID= 3 AND OI.CMFulfilmentId = @userId ORDER BY OrderID DESC     
  END    
  ELSE    
     SELECT ISNULL(s.ShipmentId,0)ShipmentId,ISNULL(s.ShipmentNumber,'')ShipmentNumber,ISNULL(s.TrackingNumber,'')TrackingNumber,ISNULL(s.CreatedBy,'')CreatedBy,   
  s.ShippingDate,ISNULL(os.OrderStatusName,'') AS Status,ISNULL(org.Name,'') AS OrganizationName,   
 ISNULL(u.Email,'') AS AssignedToCM,STUFF((Select ',' + CAST (SerialNumber AS VARCHAR(5))      
    FROM Devices D WITH(NOLOCK) WHERE D.ShipmentId=s.ShipmentId AND  SerialNumber IS NOT NULL AND SerialNumber<>'' FOR XML PATH('')),1,1,'') AS ShippedDevicesSerialNos        FROM Shipments s  WITH(NOLOCK)     
   LEFT JOIN Orderstatus os WITH(NOLOCK) ON os.OrderStatusId = s.ShipmentStatus      
      LEFT JOIN Orders ord WITH(NOLOCK) ON  ord.OrderId = s.OrderId       
      LEFT JOIN Organizations org WITH(NOLOCK) ON org.OrganizationId = ord.OrganizationId       
      LEFT JOIN Users u WITH(NOLOCK) ON u.UserId = s.CreatedBy  WHERE s.CreatedBy = @userId ORDER BY ShipmentId DESC     
      
      
 END      
      
END 
GO
/****** Object:  StoredProcedure [dbo].[USP_GetQuotations]    Script Date: 07-05-2019 13:44:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  



  -- =============================================      
-- Author:  PONMANI SASIKUMAR      
-- Create date: 17 APR 2019      
-- Description: To retirve the Quotations      
-- EXEC [USP_GetQuotations] '7349d5ee-ef02-44a0-9b32-4a325b5768cf'      
-- =============================================      
CREATE PROCEDURE [dbo].[USP_GetQuotations]       
 @userId VARCHAR(200) =''      
AS      
BEGIN      
 SET NOCOUNT ON;      
  
 DECLARE @roleName VARCHAR(200)      
 DECLARE @roleId VARCHAR(200)      
      
 SELECT TOP 1  @roleId = RoleId FROM USERROLES WITH(NOLOCK) WHERE USERID = @userId      
      
 SELECT TOP 1 @roleName = ROLENAME FROM ROLES WITH(NOLOCK) WHERE  ROLEID= @roleId      
      
 PRINT @roleId + ' - RoleID'      
 PRINT @roleName + ' - RoleName'      
      
       
 DECLARE @IsHaveFullRightsForQuotations BIT         
        
  IF EXISTS (SELECT * From roleactions  WITH (NOLOCK) where roleid=@roleId and actionid in ( select actionid from actions       
   WITH (NOLOCK) where actionname='QuotationListViewAll'))      
  BEGIN       
   SET @IsHaveFullRightsForQuotations =1      
  END      
  ELSE SET  @IsHaveFullRightsForQuotations =0      
      
       
 PRINT CASE WHEN @IsHaveFullRightsForQuotations=1 THEN 'YES' ELSE 'No' END + ' - Have Rights to view all quotations'      
      
 IF @IsHaveFullRightsForQuotations =1       
 BEGIN      
      --- To Get Latest Revision for the quotation       
      
  SELECT * INTO #LatestQuotation from (      
  SELECT max(quotationid) AS LatestQuotationID,RevisionToQuotationId  as quotationid FROM Quotations WITH(NOLOCK) where       
  RevisionToQuotationId in (Select quotationid from quotations WITH(NOLOCK))  GROUP BY RevisionToQuotationId UNION ALL       
  SELECT quotationid AS LatestQuotationID,quotationid   FROM Quotations WITH(NOLOCK)      
  where quotationid NOT IN (SELECT RevisionToQuotationId from Quotations) ) A      
      
  -- Find Quantity Fulfilled OR NOT      
      
  SELECT DISTINCT  i.LatestQuotationID,i.QuotationId,P.InventoryitemId,TotalItemsQuoted,TotalItemsPO,CASE WHEN TotalItemsQuoted =TotalItemsPO       
  THEN 1 ELSE  0 END  as QuantityFulfilled       
   INTO #QuotePOQuantity FROM #LatestQuotation i      
  LEFT JOIN ( SELECT SUM(Quantity) AS TotalItemsQuoted,InventoryitemId,QuotationId from quotationitems WITH(NOLOCK)  GROUP BY InventoryitemId, QuotationId) p      
  ON i.LatestQuotationID = p.QuotationId       
  LEFT JOIN ( SELECT SUM(Quantity) AS TotalItemsPO,InventoryitemId,QuotationId from PurchaseOrderITems A WITH(NOLOCK) INNER JOIN PurchaseOrders B WITH(NOLOCK)       
  ON A.Purchaseorderid=B.Purchaseorderid       
  GROUP BY InventoryitemId, B.QuotationId) s      
  ON s.QuotationId = i.QuotationId  AND p.InventoryitemId=s.InventoryitemId       
      
  --SELECT LatestQuotationID,QuotationId, MIN(QuantityFulfilled) as QuantityFulfilled      
  --FROM #QuotePOQuantity      
  --GROUP BY LatestQuotationID,QuotationId      
      
    SELECT ISNULL(QuotationId,0)QuotationId,ISNULL(QuoteNumber,'') QuoteNumber,CreatedDate,ISNULL(Name,'') AS OrganizationName,  
  ISNULL(CommaSeperatedPurchaseOrders,'') CommaSeperatedPurchaseOrders,ISNULL(Email,'') AS CreatedBy,ISNULL(NoOfRevision,0)NoOfRevision,    
  ISNULL(QuotationStatusName,'') AS QuoteStatus,ISNULL(QuoteStatusId,0)QuoteStatusId,ISNULL(RevisionToQuotationId,0)RevisionToQuotationId,      
  ISNULL(MIN(QuantityFulfilled),0)  as QuantityFulfilled,ISNULL(MIN(IsApproved),0)  AS IsApproved ,ISNULL(IsParentQuotation,0)IsParentQuotation FROM (      
  SELECT DISTINCT QTE.QuotationId, QTE.RevisionToQuotationId,QTE.QuoteNumber,QTE.CreatedDate,ORG.Name,STUFF((Select ',' + CAST (PONumber AS VARCHAR(50))      
  FROM PurchaseOrders PO1 WITH(NOLOCK) WHERE PO1.quotationid=PO.quotationid FOR XML PATH('')),1,1,'') AS CommaSeperatedPurchaseOrders, USR.Email,      
  NoOfRevision,QS.QuotationStatusName,QTE.QuoteStatusId,FL.QuantityFulfilled as QuantityFulfilled ,CAST(IsApproved AS INT) IsApproved,IsParentQuotation FROM QUOTATIONS QTE       
  INNER JOIN ORGANIZATIONS ORG WITH(NOLOCK) ON QTE.OrganizationId = ORG.OrganizationId      
  LEFT JOIN PURCHASEORDERS PO WITH(NOLOCK) ON QTE.QuotationId = PO.QuotationId      
  INNER JOIN USERS USR WITH(NOLOCK) ON QTE.CreatedBy = USR.UserId      
  INNER JOIN  QUOTATIONSTATUS QS WITH(NOLOCK) ON QTE.QuoteStatusId=QS.QuotationStatusId        
  LEFT JOIN #QuotePOQuantity FL ON FL.QuotationId=  QTE.QuotationId  where IsParentQuotation=1  ) A       
  GROUP BY  QuotationId,QuoteNumber,RevisionToQuotationId,CreatedDate,Name,CommaSeperatedPurchaseOrders,Email,NoOfRevision,QuotationStatusName,QuoteStatusId,IsParentQuotation      
  ORDER BY  QuotationId  DESC      
      
  DROP TABLE #LatestQuotation       
  DROP TABLE #QuotePOQuantity      
      
 END      
 ELSE      
  BEGIN      
   --- To Get Latest Revision for the quotation       
      
  SELECT * INTO #LatestQuotation1 from (      
  SELECT max(quotationid) AS LatestQuotationID,RevisionToQuotationId  as quotationid FROM Quotations WITH(NOLOCK) where       
  RevisionToQuotationId in (Select quotationid from quotations WITH(NOLOCK))  GROUP BY RevisionToQuotationId UNION ALL       
  SELECT quotationid AS LatestQuotationID,quotationid   FROM Quotations WITH(NOLOCK)      
  where quotationid NOT IN (SELECT RevisionToQuotationId from Quotations WITH(NOLOCK))) A      
      
  -- Find Quantity Fulfilled OR NOT      
      
  SELECT DISTINCT  i.LatestQuotationID,i.QuotationId,P.InventoryitemId,TotalItemsQuoted,TotalItemsPO,CASE WHEN TotalItemsQuoted =TotalItemsPO       
  THEN 1 ELSE  0 END  as QuantityFulfilled       
   INTO #QuotePOQuantity1 FROM #LatestQuotation1 i      
  LEFT JOIN ( SELECT SUM(Quantity) AS TotalItemsQuoted,InventoryitemId,QuotationId from quotationitems   GROUP BY InventoryitemId, QuotationId) p      
  ON i.LatestQuotationID = p.QuotationId       
  LEFT JOIN ( SELECT SUM(Quantity) AS TotalItemsPO,InventoryitemId,QuotationId from PurchaseOrderITems A INNER JOIN PurchaseOrders B       
  ON A.Purchaseorderid=B.Purchaseorderid      
  GROUP BY InventoryitemId, B.QuotationId) s      
  ON s.QuotationId = i.LatestQuotationID   AND p.InventoryitemId=s.InventoryitemId      
      
  --SELECT LatestQuotationID,QuotationId, MIN(QuantityFulfilled) as QuantityFulfilled      
  --FROM #QuotePOQuantity      
  --GROUP BY LatestQuotationID,QuotationId      
      
  SELECT ISNULL(QuotationId,0)QuotationId,ISNULL(QuoteNumber,'') QuoteNumber,CreatedDate,ISNULL(Name,'') AS OrganizationName,  
  ISNULL(CommaSeperatedPurchaseOrders,'') CommaSeperatedPurchaseOrders,ISNULL(Email,'') AS CreatedBy,ISNULL(NoOfRevision,0)NoOfRevision,    
  ISNULL(QuotationStatusName,'') AS QuoteStatus,ISNULL(QuoteStatusId,0)QuoteStatusId,ISNULL(RevisionToQuotationId,0)RevisionToQuotationId,      
  ISNULL(MIN(QuantityFulfilled),0)  as QuantityFulfilled,ISNULL(MIN(IsApproved),0)  AS IsApproved ,ISNULL(IsParentQuotation,0)IsParentQuotation FROM (      
  SELECT DISTINCT QTE.QuotationId,QTE.QuoteNumber, QTE.RevisionToQuotationId,QTE.CreatedDate,ORG.Name,STUFF((Select ',' + CAST (PONumber AS VARCHAR(50))      
  FROM PurchaseOrders PO1 WITH(NOLOCK) WHERE PO1.quotationid=PO.quotationid FOR XML PATH('')),1,1,'') AS CommaSeperatedPurchaseOrders, USR.Email,      
  NoOfRevision,QS.QuotationStatusName,QTE.QuoteStatusId,FL.QuantityFulfilled as QuantityFulfilled,CAST(IsApproved AS INT) IsApproved ,IsParentQuotation FROM QUOTATIONS QTE       
  INNER JOIN ORGANIZATIONS ORG WITH(NOLOCK) ON QTE.OrganizationId = ORG.OrganizationId      
  LEFT JOIN PURCHASEORDERS PO WITH(NOLOCK) ON QTE.QuotationId = PO.QuotationId      
  INNER JOIN USERS USR  WITH(NOLOCK) ON QTE.CreatedBy = USR.UserId      
  INNER JOIN  QUOTATIONSTATUS QS WITH(NOLOCK) ON QTE.QuoteStatusId=QS.QuotationStatusId        
  LEFT JOIN #QuotePOQuantity1 FL WITH(NOLOCK) ON FL.QuotationId=  QTE.QuotationId  where IsParentQuotation=1 AND  (QTE.CreatedBy =@userId OR QTE.QuoteStatusId=1)  ) A       
  GROUP BY  QuotationId,QuoteNumber,RevisionToQuotationId,CreatedDate,Name,CommaSeperatedPurchaseOrders,Email,NoOfRevision,QuotationStatusName,QuoteStatusId,IsParentQuotation      
  ORDER BY  QuotationId  DESC      
      
  DROP TABLE #LatestQuotation1       
  DROP TABLE #QuotePOQuantity1      
      
  --SELECT DISTINCT QTE.QuotationId,QTE.QuoteNumber,QTE.CreatedDate,ORG.Name,STUFF((Select ',' + CAST (PurchaseOrderId AS VARCHAR(5))      
  --FROM PurchaseOrders PO1 WHERE PO1.quotationid=PO.quotationid FOR XML PATH('')),1,1,'') AS CommaSeperatedPurchaseOrders, USR.Email,      
  --NoOfRevision,QS.QuotationStatusName,QTE.QuoteStatusId ,1 as QuantityFulfilled FROM QUOTATIONS QTE       
  --INNER JOIN ORGANIZATIONS ORG ON QTE.OrganizationId = ORG.OrganizationId      
  --LEFT JOIN PURCHASEORDERS PO ON QTE.QuotationId = PO.QuotationId      
  --INNER JOIN USERS USR  ON QTE.CreatedBy = USR.UserId      
  --INNER JOIN  QUOTATIONSTATUS QS ON QTE.QuoteStatusId=QS.QuotationStatusId       
  --  where IsParentQuotation=1 AND  (QTE.CreatedBy =@userId OR QTE.QuoteStatusId=1)      
  --ORDER BY  QTE.QuotationId  DESC      
  END      
       
END      
       
GO
/****** Object:  StoredProcedure [dbo].[USP_GetShipments]    Script Date: 07-05-2019 13:44:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
-- =============================================          
-- Author:  PONMANI SASIKUMAR          
-- Create date: 17 APR 2019          
-- Description: To retirve the Orders Pending for shipment and Shipped orders           
-- EXEC [USP_GetShipments] '8a843e69-ccdc-40aa-bd5f-216b08945895'        
--EXEC [USP_GetShipments] 'f245f727-9e4b-4ca8-bff7-5ad9fc5eea7c'        
-- =============================================          
CREATE PROCEDURE [dbo].[USP_GetShipments]           
 @userId VARCHAR(200)= ''
AS          
BEGIN          
 SET NOCOUNT ON;          
 DECLARE @roleName VARCHAR(200)          
 DECLARE @roleId VARCHAR(200)          
          
 SELECT TOP 1  @roleId = RoleId FROM USERROLES WITH(NOLOCK) WHERE USERID = @userId          
          
 SELECT TOP 1 @roleName = ROLENAME FROM ROLES WITH(NOLOCK) WHERE  ROLEID= @roleId          
          
 PRINT @roleId + ' - RoleID'          
 PRINT @roleName + ' - RoleName'          
          
           
 DECLARE @IsAllShipments BIT               
            
  IF @roleName = 'CMFulfilment'          
  BEGIN           
   SET @IsAllShipments =0          
  END          
  ELSE SET @IsAllShipments =1          
              
 PRINT CASE WHEN @IsAllShipments=0 THEN 'YES' ELSE 'No' END + ' - Only CM Created/Assigned'          
          
 IF @IsAllShipments =1  AND (@roleName = 'AdaptrumAdmin' OR @roleName='SuperAdmin')          
 BEGIN          
       
   SELECT ISNULL(OrderID,0)OrderID,ISNULL(OrderNumber,'')OrderNumber,ISNULL(AB.FormattedAddress,'') AS FormattedAddress,      
   ISNULL(ord.OrderStatusID,0) AS OrderStatusId,'Ready to Ship' AS OrderStatus,CreatedDate AS PlacedDate,          
    (SELECT TOP 1 ISNULL(Email,'') FROM orderitems A WITH(NOLOCK)INNER JOIN USERS U WITH(NOLOCK)ON A.CMFulfilmentId = U.UserId WHERE orderid = ORD.orderid) AS  AssignedToCM          
    FROM ORDERS ORD          
    LEFT JOIN ADDRESSBOOK AB WITH(NOLOCK)ON ORD.BillToAddressId =AB.AddressId  WHERE ORD.OrderStatusID= 3  ORDER BY OrderID DESC        
      
    SELECT ISNULL(s.ShipmentId,0)ShipmentId,ISNULL(s.ShipmentNumber,'')ShipmentNumber,ISNULL(s.TrackingNumber,'')TrackingNumber,ISNULL(s.CreatedBy,'')CreatedBy,       
  s.ShippingDate,ISNULL(os.OrderStatusName,'') AS Status,ISNULL(org.Name,'') AS OrganizationName,       
 ISNULL(u.Email,'') AS AssignedToCM,STUFF((Select ',' + CAST (SerialNumber AS VARCHAR(MAX))          
    FROM Devices D WITH(NOLOCK) WHERE D.ShipmentId=s.ShipmentId AND  SerialNumber IS NOT NULL AND SerialNumber<>'' FOR XML PATH('')),1,1,'') AS ShippedDevicesSerialNos          
 FROM Shipments s WITH(NOLOCK) LEFT JOIN Orderstatus os ON os.OrderStatusId = s.ShipmentStatus          
    LEFT JOIN Orders ord WITH(NOLOCK) ON  ord.OrderId = s.OrderId LEFT JOIN Organizations org WITH(NOLOCK) ON org.OrganizationId = ord.OrganizationId          
    LEFT JOIN Users u WITH(NOLOCK) ON u.UserId = s.CreatedBy WHERE ord.OrderStatusID=5  ORDER BY ShipmentId DESC        
     END  
 ELSE           
   BEGIN  
   SELECT DISTINCT ISNULL(ORD.OrderID,0)OrderID,ISNULL(OrderNumber,'')OrderNumber,ISNULL(AB.FormattedAddress,'')FormattedAddress,ISNULL(ord.OrderStatusID,0) AS OrderStatusId,      
   'Ready to Ship' AS OrderStatus,CreatedDate as PlacedDate,            
    (SELECT TOP 1 Email from orderitems A WITH(NOLOCK) INNER JOIN USERS U WITH(NOLOCK) ON A.CMFulfilmentId = U.UserId where orderid = ORD.orderid) as  AssignedToCM              
    FROM ORDERS ORD  WITH(NOLOCK)        
   LEFT JOIN ADDRESSBOOK AB WITH(NOLOCK) ON ORD.BillToAddressId =AB.AddressId          
   LEFT JOIN ORDERITEMS OI WITH(NOLOCK) ON OI.OrderId=ORD.OrderID   WHERE ORD.OrderStatusID= 3 AND OI.CMFulfilmentId = @userId ORDER BY OrderID DESC         
       
     SELECT ISNULL(s.ShipmentId,0)ShipmentId,ISNULL(s.ShipmentNumber,'')ShipmentNumber,ISNULL(s.TrackingNumber,'')TrackingNumber,ISNULL(s.CreatedBy,'')CreatedBy,       
  s.ShippingDate,ISNULL(os.OrderStatusName,'') AS Status,ISNULL(org.Name,'') AS OrganizationName,       
 ISNULL(u.Email,'') AS AssignedToCM,STUFF((Select ',' + CAST (SerialNumber AS VARCHAR(MAX))          
    FROM Devices D WITH(NOLOCK) WHERE D.ShipmentId=s.ShipmentId AND  SerialNumber IS NOT NULL AND SerialNumber<>'' FOR XML PATH('')),1,1,'') AS ShippedDevicesSerialNos        FROM Shipments s  WITH(NOLOCK)         
   LEFT JOIN Orderstatus os WITH(NOLOCK) ON os.OrderStatusId = s.ShipmentStatus          
      LEFT JOIN Orders ord WITH(NOLOCK) ON  ord.OrderId = s.OrderId           
      LEFT JOIN Organizations org WITH(NOLOCK) ON org.OrganizationId = ord.OrganizationId           
      LEFT JOIN Users u WITH(NOLOCK) ON u.UserId = s.CreatedBy  WHERE s.CreatedBy = @userId ORDER BY ShipmentId DESC         
      END    
          
END 
GO
/****** Object:  StoredProcedure [dbo].[USP_GetShopNowItems]    Script Date: 07-05-2019 13:44:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================    
-- Author:  PONMANI SASIKUMAR    
-- Create date: 24 APR 2019    
-- Description: To retirve Shop now items    
-- EXEC [USP_GetShopNowItems] '03a1446b-4a03-4bca-a812-e6ae946677d9'
-- EXEC [USP_GetShopNowItems] '0ca7779c-4f5a-4729-acca-3c9380af09b5'    
-- EXEC [USP_GetShopNowItems] '54cd3a88-465c-4be9-a45d-184fe97c0fcc'   
-- =============================================    
CREATE PROCEDURE [dbo].[USP_GetShopNowItems]    
 @userId VARCHAR(200)= ''     
AS
BEGIN

SET NOCOUNT ON;     
 DECLARE @roleName VARCHAR(200)    
 DECLARE @roleId VARCHAR(200)    
  DECLARE @OrganizationId INT
 DECLARE @CustomerCategoryId INT
 DECLARE @PricingCategoryId INT
    
 SELECT TOP 1  @roleId = RoleId FROM USERROLES  WITH (NOLOCK) WHERE USERID = @userId    
    
 SELECT TOP 1 @roleName = ROLENAME FROM ROLES  WITH (NOLOCK) WHERE  ROLEID= @roleId    
    
 PRINT @roleId + ' - RoleID'    
 PRINT @roleName + ' - RoleName' 
 
    

 SELECT TOP 1 @OrganizationId = OrganizationId FROM OrganizationUsers where userid=@userId
 SELECT TOP 1 @CustomerCategoryId = CustomerTypeId, @PricingCategoryId =PricingCategoryId 
 FROM Organizations where  OrganizationId=@OrganizationId
 
 IF @OrganizationId<>0 AND @CustomerCategoryId=4
 BEGIN

 SELECT INV.InventoryItemID, INV.ItemName,
   ROUND(INV.Price,2) as StandardPrice,
 CAST(CASE WHEN CP.Price IS NULL  THEN  ROUND(INV.Price,2) 
 WHEN CP.Price IS NOT NULL AND CPD.Discount  IS NOT NULL  THEN  ROUND( CP.Price -( CP.Price *(CPD.Discount/100) ),2)
 ELSE   ROUND(CP.Price,2) END as DECIMAL(18,2)) as Price ,

	INV.Stock, INV.PartNumber,
 (SELECT TOP 1 FileId   from files where fileid = FE.Fileid) FileId,
 (SELECT TOP 1 Filename   from files where fileid = FE.Fileid) [Filename],
  (SELECT TOP 1 FilePath  from files where fileid = FE.Fileid) FilePath,
  0.00 as Discount , CAST (1 as BIT) as IsAirbandCustomer,
  (Select ISNULL(SUM(Quantity),0) from cartitems where CreatedBy =@userid) as CartCount
 FROM  INVENTORYITEMS INV LEFT JOIN  [CustomerPricing] CP ON INV.Inventoryitemid = CP.InventoryItemID 
 LEFT JOIN CustomerPricingDiscounts CPD ON CPD.CustomerPricingId =CP.CustomerPricingId  AND PricingCAtegoryid=@PricingCategoryId
 LEFT JOIN  FILES FE ON FE.FileParentId = INV.Inventoryitemid  AND FileTypeId=2 
 WHERE  INV.IsActive=1
 END
 ELSE
 BEGIN
 SELECT InventoryItemID,INV.ItemName, CAST(ROUND(INV.Price,2) as DECIMAL(18,2)) as Price,
 ROUND(INV.Price,2) as StandardPrice,
  INV.Stock, INV.PartNumber,
 (SELECT TOP 1 FileId   from files where fileid = FE.Fileid) FileId,
 (SELECT TOP 1 Filename   from files where fileid = FE.Fileid) [Filename],
  (SELECT TOP 1 FilePath  from files where fileid = FE.Fileid) FilePath,
  0.00 as Discount,    CAST (0 as BIT) as IsAirbandCustomer ,  
  (Select ISNULL(SUM(Quantity),0) from cartitems where CreatedBy =@userid) as CartCount
   FROM  INVENTORYITEMS INV   LEFT JOIN  FILES FE ON FE.FileParentId = INV.Inventoryitemid  AND FileTypeId=2 
   WHERE INV.IsActive=1
 END

END
 
GO
/****** Object:  StoredProcedure [dbo].[USP_GetUserCartItems]    Script Date: 07-05-2019 13:44:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================      
-- Author:  PONMANI SASIKUMAR      
-- Create date: 25 APR 2019      
-- Description: To retirve User Cart items       
-- EXEC [USP_GetUserCartItems] 'a161336d-deb0-4acc-a412-cef650b216d1'  
-- EXEC [USP_GetUserCartItems] '0ca7779c-4f5a-4729-acca-3c9380af09b5'      
-- EXEC [USP_GetUserCartItems] 'd31b7562-4b30-4422-9ef7-6ded06316f35'     
-- =============================================      
CREATE PROCEDURE [dbo].[USP_GetUserCartItems]      
 @userId VARCHAR(200)= ''       
AS  
BEGIN  
  
SET NOCOUNT ON;       
 DECLARE @roleName VARCHAR(200)      
 DECLARE @roleId VARCHAR(200)      
  DECLARE @OrganizationId INT  
 DECLARE @CustomerCategoryId INT  
 DECLARE @PricingCategoryId INT  
      
 SELECT TOP 1  @roleId = RoleId FROM USERROLES  WITH (NOLOCK) WHERE USERID = @userId      
      
 SELECT TOP 1 @roleName = ROLENAME FROM ROLES  WITH (NOLOCK) WHERE  ROLEID= @roleId      
      
 PRINT @roleId + ' - RoleID'      
 PRINT @roleName + ' - RoleName'   
  
 DECLARE @DiscountLimit decimal   
 IF @roleName='SuperAdmin' OR @roleName='AdaptrumAdmin'
 BEGIN
  SET @DiscountLimit=100;
 END
 ELSE IF @roleName ='SalesExecutive'  
 BEGIN  
 SET @DiscountLimit =(select ApplicationSettingValue From applicationsettings where ApplicationSettingName='SaleExecutiveDiscount')  
 END  
 ELSE IF @roleName ='Controller'  
 BEGIN  
  SET @DiscountLimit =(select ApplicationSettingValue From applicationsettings where ApplicationSettingName='ControllerDiscount')  
 END   
 
  
 ELSE   SET @DiscountLimit = 0  
  
  
 SELECT TOP 1 @OrganizationId = OrganizationId FROM OrganizationUsers where userid=@userId  
 SELECT TOP 1 @CustomerCategoryId = CustomerTypeId, @PricingCategoryId =PricingCategoryId FROM Organizations where  OrganizationId=@OrganizationId  
   
 IF @OrganizationId<>0 AND @CustomerCategoryId=4  
 BEGIN  
  
 SELECT CI.CartItemID,CI.InventoryItemID, INV.ItemName,  
CAST(CASE WHEN CP.Price IS NULL  THEN  ROUND(INV.Price,2)   
 WHEN CP.Price IS NOT NULL AND CPD.Discount  IS NOT NULL  THEN  ROUND( CP.Price -( CP.Price *(CPD.Discount/100) ),2)  
 ELSE   ROUND(CP.Price,2) END as DECIMAL(18,2)) as Price ,  
 INV.Stock, INV.PartNumber,  
 (SELECT TOP 1 FileId   from files where fileid = FE.Fileid) FileId,  
 (SELECT TOP 1 Filename   from files where fileid = FE.Fileid) [Filename],  
 (SELECT TOP 1 FilePath  from files where fileid = FE.Fileid) FilePath,  
 CI.Discount , CAST (1 as BIT) as IsAirbandCustomer,  
 (Select ISNULL(SUM(Quantity),0) from cartitems where CreatedBy =@userid) as CartCount,  
 CI.Quantity,CAST(ISNULL(@DiscountLimit,0) as decimal(10,2))  as DiscountLimit,  
 @OrganizationId as UserOrganizationId  
 FROM CARTITEMS CI INNER JOIN  INVENTORYITEMS INV ON CI.Inventoryitemid=INV.Inventoryitemid   
 LEFT JOIN  [CustomerPricing] CP ON INV.Inventoryitemid = CP.InventoryItemID   
 LEFT JOIN CustomerPricingDiscounts CPD ON CPD.CustomerPricingId =CP.CustomerPricingId  AND PricingCAtegoryid=@PricingCategoryId  
 LEFT JOIN  FILES FE ON FE.FileParentId = INV.Inventoryitemid  AND FileTypeId=2  WHERE CI.CreatedBy=@userId  
 END  
 ELSE  
 BEGIN  
 SELECT CI.CartItemID,CI.InventoryItemID,INV.ItemName,INV.Price,  
 INV.Stock, INV.PartNumber,  
 (SELECT TOP 1 FileId   from files where fileid = FE.Fileid) FileId,  
 (SELECT TOP 1 Filename   from files where fileid = FE.Fileid) [Filename],  
 (SELECT TOP 1 FilePath  from files where fileid = FE.Fileid) FilePath,  
 CI.Discount ,CAST (0 as BIT) as IsAirbandCustomer ,    
 (Select ISNULL(SUM(Quantity),0) from cartitems where CreatedBy =@userid) as CartCount,  
 CI.Quantity,CAST(ISNULL(@DiscountLimit,0) as decimal(10,2))  as DiscountLimit,  
 @OrganizationId as UserOrganizationId  
 FROM CARTITEMS CI INNER JOIN  INVENTORYITEMS INV ON CI.Inventoryitemid=INV.Inventoryitemid   
 LEFT JOIN  FILES FE ON FE.FileParentId = INV.Inventoryitemid  AND FileTypeId=2  WHERE CI.CreatedBy=@userId  
 END  
  
END  
   
  
GO
/****** Object:  StoredProcedure [dbo].[USP_GetUserDashboardCount]    Script Date: 07-05-2019 13:44:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  PONMANI SASIKUMAR  
-- Create date: 16 APR 2019  
-- Description: To retirve the User Dashboard count  
-- EXEC USP_GetUserDashboardCount '09916783-ceb4-4ace-ba66-6b467a50f3c1'  
-- =============================================  
CREATE PROCEDURE [dbo].[USP_GetUserDashboardCount]   
 @userId VARCHAR(200) =''  
AS  
BEGIN  
 SET NOCOUNT ON;   
  
 DECLARE @roleName VARCHAR(200)  
 DECLARE @roleId VARCHAR(200)  
  
 SELECT TOP 1  @roleId = RoleId FROM USERROLES WHERE USERID = @userId  
  
 SELECT TOP 1 @roleName = ROLENAME FROM ROLES WHERE  ROLEID= @roleId  
  
 PRINT @roleId + ' - RoleID'  
 PRINT @roleName + ' - RoleName'  
  
 DECLARE @CartItemsCount INT  
 DECLARE @userPlacedOrdersCount  INT  
 DECLARE @userRejectedOrdersCount  INT  
 DECLARE @userShippedOrdersCount INT  
 DECLARE @userAssignedReadyForShipmentCount INT  
 DECLARE @totalPOwaitingForApproval INT  
 DECLARE @totalPlacedOrdersCount INT  
 DECLARE @totalApprovedOrdersCount INT  
 DECLARE @totalInShipmentCount INT  
 DECLARE @totalShippedCount INT  
  
 DECLARE @IsHaveFullRightsForOrder BIT    
 DECLARE @IsHaveFullRightsForShipment BIT   
  
  
 DECLARE @FirstInventoryItemName NVARCHAR(500)  
 DECLARE @FirstInventoryItemID INT  
 DECLARE @FirstInventoryItemStock INT  
 DECLARE @SecondInventoryItemName NVARCHAR(500)  
 DECLARE @SecondInventoryItemStock INT  
  
 -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------  
 SELECT TOP 1 @FirstInventoryItemName= ItemName, @FirstInventoryItemID = InventoryitemId ,@FirstInventoryItemStock =stock   
 FROM INVENTORYITEMS   WITH (NOLOCK) WHERE ISACTIVE=1 ORDER BY INVENTORYITEMID ASC  
  
 SELECT TOP 1 @SecondInventoryItemName= ItemName ,@SecondInventoryItemStock =stock FROM INVENTORYITEMS   WITH (NOLOCK)  
 WHERE ISACTIVE=1 AND InventoryitemId <> @FirstInventoryItemID ORDER BY INVENTORYITEMID ASC  
 -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------  
   
  IF EXISTS (SELECT * From roleactions  WITH (NOLOCK) where roleid=@roleId and actionid in ( select actionId from actions   
   WITH (NOLOCK) where actionname='OrderListViewAll'))  
  BEGIN   
   SET @IsHaveFullRightsForOrder =1  
  END  
  ELSE SET  @IsHaveFullRightsForOrder =0  
  
   
 PRINT CASE WHEN @IsHaveFullRightsForOrder=1 THEN 'YES' ELSE 'No' END + ' - Have Rights to view all orders'  
  
  
  IF @roleName <> 'CMFulfilment'  
  BEGIN   
   SET @IsHaveFullRightsForShipment =1  
  END  
  ELSE SET  @IsHaveFullRightsForShipment =0  
  
  PRINT CASE WHEN @IsHaveFullRightsForShipment=1 THEN 'YES' ELSE 'No' END + ' - Have Rights to view all shipments'  
  
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
  SELECT @CartItemsCount = COUNT(*) FROM CARTITEMS  WITH (NOLOCK) WHERE CREATEDBY = @userId  
  SELECT @totalPOwaitingForApproval =   COUNT(*) FROM quotations  WITH (NOLOCK) where QuoteStatusId = 6 OR QuoteStatusId = 9  
  
  IF @IsHaveFullRightsForOrder = 1  
  BEGIN   
  SELECT @totalPlacedOrdersCount= COUNT (*) FROM ORDERS  WITH (NOLOCK) WHERE orderstatusid=2   
  SELECT @totalApprovedOrdersCount = COUNT (*) FROM ORDERS  WITH (NOLOCK)  WHERE orderstatusid=3   
  SELECT @userPlacedOrdersCount= @totalPlacedOrdersCount 
  SELECT @userRejectedOrdersCount = COUNT (*) FROM ORDERS   WITH (NOLOCK) WHERE   orderstatusid=4    
  END  
  ELSE  
  BEGIN   
   SELECT @userPlacedOrdersCount= COUNT (*) FROM ORDERS   WITH (NOLOCK) WHERE CREATEDBY = @userId AND orderstatusid=2  
   SELECT @userRejectedOrdersCount = COUNT (*) FROM ORDERS  WITH (NOLOCK)  WHERE CREATEDBY = @userId AND orderstatusid=4    
  END  
  
   IF @IsHaveFullRightsForShipment = 1  
  BEGIN    
  SELECT @totalInShipmentCount = COUNT(*) FROM ORDERS   WITH (NOLOCK) WHERE orderstatusid=3  
  SELECT @totalShippedCount = COUNT(*)  From orders where orderid in (select distinct orderid from shipments) and orderstatusid=5
  SELECT @userShippedOrdersCount = COUNT(*)  From orders where orderid in (select distinct orderid from shipments) and orderstatusid=5
  SELECT @userAssignedReadyForShipmentCount = COUNT (*) FROM ORDERS   WITH (NOLOCK)  WHERE   
  ORDERID in (SELECT DISTINCT ORDERID FROM ORDERITEMS  WITH (NOLOCK)) AND orderstatusid=3   
  
  END  
  ELSE  
  BEGIN     
   SELECT @userShippedOrdersCount = COUNT(*)  From orders where orderid in (select distinct orderid from shipments  WHERE CREATEDBY = @userId) and orderstatusid=5
      
   SELECT @userAssignedReadyForShipmentCount = COUNT (*) FROM ORDERS  WITH (NOLOCK)    
    WHERE ORDERID in (SELECT DISTINCT ORDERID FROM ORDERITEMS  WITH (NOLOCK)  WHERE CMFulfilmentID=@userId) AND orderstatusid=3   
  END  
  
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
  SELECT ISNULL(@CartItemsCount,0) AS  CartItemsCount,ISNULL(@userPlacedOrdersCount,0) AS  userPlacedOrdersCount,
  ISNULL(@userRejectedOrdersCount,0) AS  userRejectedOrdersCount,  
  ISNULL(@userShippedOrdersCount,0) AS  userShippedOrdersCount,ISNULL(@userAssignedReadyForShipmentCount,0) AS userAssignedReadyForShipmentCount,  
  ISNULL(@totalPOwaitingForApproval,0) AS  totalPOwaitingForApproval,  
  ISNULL(@totalPlacedOrdersCount,0) AS  totalPlacedOrdersCount,ISNULL(@totalApprovedOrdersCount,0) AS  totalApprovedOrdersCount,  
  ISNULL(@totalInShipmentCount,0) AS  totalInShipmentCount,ISNULL(@totalShippedCount,0) AS  totalShippedCount,  
  ISNULL(@FirstInventoryItemName,0) AS FirstInventoryItemName,ISNULL(@FirstInventoryItemStock,0) AS FirstInventoryItemStock,
  ISNULL(@SecondInventoryItemName,0) AS SecondInventoryItemName,ISNULL(@SecondInventoryItemStock,0) AS SecondInventoryItemStock  
   
END  


GO
/****** Object:  StoredProcedure [dbo].[USP_GetUserProfileAndRoleActions]    Script Date: 07-05-2019 13:44:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================      
-- Author:  PONMANI SASIKUMAR      
-- Create date: 26 APR 2019      
-- Description: To retirve the User Profile And Role Actions Info   
-- EXEC [USP_GetUserProfileAndRoleActions] 'be5738db-efe0-4659-ace5-7ace7696e243'
-- =============================================      
CREATE PROCEDURE [dbo].[USP_GetUserProfileAndRoleActions]       
 @userId VARCHAR(200)= ''      
AS      
BEGIN     
 SET NOCOUNT ON;   
SELECT USR.UserId, CAST (USR.Isactive as BIT) as Isactive,UR.RoleID,R.RoleName,
  CAST(CASE WHEN  (SELECT COUNT(*) FROM USERPROFILE WHERE userid=USR.UserID)=0 THEN 0 ELSE 1 END AS BIT) AS    IsProfileExist ,
UP.FirstName,UP.LastName,USR.Email,ISNULL(UO.Organizationid,0) as Organizationid,
ISNULL(ACT.ActionName,'') as ActionName,ISNULL(ACT.ModuleId,0) as ModuleId ,
(SELECT COUNT(*) FROM CartItems where createdby=USR.UserID) as CartCount
FROM USERS USR LEFT JOIN USERPROFILE UP ON USR.Userid=UP.UserID 
LEFT JOIN OrganizationUsers UO ON  UO.UserID= USR.UserID 
LEFT JOIN UserRoles UR ON UR.UserID=USR.USerid 
Left JOIN Roles R ON R.RoleID = UR.RoleId
LEFT JOIN RoleActions RA ON RA.RoleID = UR.Roleid
LEFT JOIN Actions ACT ON ACT.actionid=RA.actionid WHERE USR.UserId=@userId
END
GO
