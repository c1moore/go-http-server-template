package health

import "github.com/gin-gonic/gin"

func InitRoutes(r *gin.RouterGroup) {
	r.GET("/ready", handleReadinessProbe)
	r.GET("/live", handleLivenessProbe)
}

func handleReadinessProbe(c *gin.Context) {
	res, err := getHealth()
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, res)
}

func handleLivenessProbe(c *gin.Context) {
	c.Status(200)
}
