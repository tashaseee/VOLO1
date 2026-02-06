-- SQL script to add placeholder images to events
-- This will add image URLs to events that don't have them

UPDATE events 
SET image_url = CASE 
    WHEN id % 8 = 0 THEN '/uploads/events/placeholder_1.jpg'
    WHEN id % 8 = 1 THEN '/uploads/events/placeholder_2.jpg'
    WHEN id % 8 = 2 THEN '/uploads/events/placeholder_3.jpg'
    WHEN id % 8 = 3 THEN '/uploads/events/placeholder_4.jpg'
    WHEN id % 8 = 4 THEN '/uploads/events/placeholder_5.jpg'
    WHEN id % 8 = 5 THEN '/uploads/events/placeholder_6.jpg'
    WHEN id % 8 = 6 THEN '/uploads/events/placeholder_7.jpg'
    ELSE '/uploads/events/placeholder_8.jpg'
END
WHERE image_url IS NULL OR image_url = '';

-- Show results
SELECT id, title, image_url FROM events;
